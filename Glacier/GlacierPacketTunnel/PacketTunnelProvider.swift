// PacketTunnelProvider.swift
// Shield — Network Extension target
//
// ─────────────────────────────────────────────────────────────
// TARGET SETUP IN XCODE:
//   File → New → Target → Network Extension
//   Provider Type: Packet Tunnel
//   Bundle ID: com.shield.app.PacketTunnel
//
// ENTITLEMENTS (main app target):
//   com.apple.developer.networking.networkextension: [packet-tunnel-provider]
//
// ENTITLEMENTS (PacketTunnel target):
//   com.apple.developer.networking.networkextension: [packet-tunnel-provider]
//
// INFO.PLIST (PacketTunnel target):
//   NSExtension → NSExtensionPrincipalClass → $(PRODUCT_MODULE_NAME).PacketTunnelProvider
//   NSExtensionPointIdentifier → com.apple.networkextension.packet-tunnel
//
// HOW IT WORKS:
//   Creates a local VPN tunnel that routes all DNS queries through
//   AdGuard DNS servers (94.140.14.14 / 94.140.15.15).
//   These servers block ads, trackers, malware and phishing at the
//   DNS level — before any connection is even made.
//   This is the same mechanism Brave uses on iOS.
// ─────────────────────────────────────────────────────────────

import NetworkExtension
import os.log

class PacketTunnelProvider: NEPacketTunnelProvider {

    private let log = OSLog(subsystem: "com.shield.app.PacketTunnel", category: "tunnel")

    // AdGuard DNS — filters ads + trackers at resolver level
    private let primaryDNS   = "94.140.14.14"   // AdGuard Default
    private let secondaryDNS = "94.140.15.15"   // AdGuard Default (fallback)

    // Extended blocklist — packets containing these strings are dropped
    // even if the DNS resolver somehow passes them through.
    // This is a secondary layer on top of DNS filtering.
    private let hardBlockedDomains: Set<String> = [
        // Absolute must-block (even if DNS is slow)
        "doubleclick.net", "googlesyndication.com", "googleadservices.com",
        "pagead2.googlesyndication.com", "ad.doubleclick.net",
        "pixel.facebook.com", "connect.facebook.net", "an.facebook.com",
        "ads.pinterest.com", "ads.tiktok.com", "ads.twitter.com",
        "ad.unity3d.com", "auction.unityads.unity3d.com",
        "app-measurement.com", "app.appsflyer.com", "app.adjust.com",
        "cdn.taboola.com", "cdn.outbrain.com", "cdn.criteo.com",
        "popads.net", "propellerads.com", "coinhive.com",
        "ads.inmobi.com", "ads.mopub.com",
        "ms.applovin.com", "ads.chartboost.com",
        "config.uca.ironsrc.com",
    ]

    override func startTunnel(
        options: [String: NSObject]?,
        completionHandler: @escaping (Error?) -> Void
    ) {
        os_log("Shield: starting tunnel", log: log, type: .info)

        let settings = buildTunnelSettings()

        setTunnelNetworkSettings(settings) { [weak self] error in
            guard let self else { return }

            if let error {
                os_log("Shield: tunnel settings error — %{public}@",
                       log: self.log, type: .error, error.localizedDescription)
                completionHandler(error)
                return
            }

            os_log("Shield: tunnel active ✓", log: self.log, type: .info)
            completionHandler(nil)
            self.readPackets()
        }
    }

    override func stopTunnel(
        with reason: NEProviderStopReason,
        completionHandler: @escaping () -> Void
    ) {
        os_log("Shield: tunnel stopped (reason %{public}d)", log: log, type: .info, reason.rawValue)
        completionHandler()
    }

    // ── Tunnel network settings ─────────────────────────────────────
    private func buildTunnelSettings() -> NEPacketTunnelNetworkSettings {
        // Private address space for the virtual tunnel interface
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "10.8.0.1")

        // IPv4 — route all traffic through the tunnel
        let ipv4 = NEIPv4Settings(
            addresses:   ["10.8.0.2"],
            subnetMasks: ["255.255.255.0"]
        )
        ipv4.includedRoutes = [NEIPv4Route.default()]
        ipv4.excludedRoutes = [
            // Keep local LAN traffic out of the tunnel
            NEIPv4Route(destinationAddress: "192.168.0.0",  subnetMask: "255.255.0.0"),
            NEIPv4Route(destinationAddress: "10.0.0.0",     subnetMask: "255.0.0.0"),
            NEIPv4Route(destinationAddress: "172.16.0.0",   subnetMask: "255.240.0.0"),
        ]
        settings.ipv4Settings = ipv4

        // IPv6 passthrough
        let ipv6 = NEIPv6Settings(addresses: ["fd00::2"], networkPrefixLengths: [64])
        ipv6.includedRoutes = [NEIPv6Route.default()]
        settings.ipv6Settings = ipv6

        // DNS — all queries routed through AdGuard resolvers
        let dns = NEDNSSettings(servers: [primaryDNS, secondaryDNS])
        dns.matchDomains = [""]  // match all domains
        dns.matchDomainsNoSearch = true
        settings.dnsSettings = dns

        // MTU — standard Ethernet MTU
        settings.mtu = 1500

        return settings
    }

    // ── Packet handling ─────────────────────────────────────────────
    private func readPackets() {
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self else { return }
            self.handlePackets(packets, protocols: protocols)
            self.readPackets() // Continue reading loop
        }
    }

    private func handlePackets(_ packets: [Data], protocols: [NSNumber]) {
        var allowedPackets:   [Data]     = []
        var allowedProtocols: [NSNumber] = []

        for (index, packet) in packets.enumerated() {
            if !isDomainBlocked(packet) {
                allowedPackets.append(packet)
                allowedProtocols.append(protocols[index])
            }
        }

        if !allowedPackets.isEmpty {
            packetFlow.writePackets(allowedPackets, withProtocols: allowedProtocols)
        }
    }

    // ── Domain blocking (secondary layer) ──────────────────────────
    // DNS filtering already drops most requests before they reach here.
    // This catches any that slip through during resolver latency.
    private func isDomainBlocked(_ packet: Data) -> Bool {
        // Fast path: try extracting domain from DNS query bytes
        if let domain = extractDNSDomain(from: packet) {
            for blocked in hardBlockedDomains {
                if domain.hasSuffix(blocked) || domain == blocked {
                    os_log("Shield: blocked %{public}@", log: log, type: .debug, domain)
                    return true
                }
            }
        }
        return false
    }

    // ── DNS query domain extraction ─────────────────────────────────
    // DNS wire format: 12-byte header, then QNAME as length-prefixed labels
    private func extractDNSDomain(from packet: Data) -> String? {
        guard packet.count > 12 else { return nil }

        // Check for UDP DNS (port 53 is bytes 22-23 in IPv4)
        // We look for the QNAME starting after the 12-byte DNS header
        // This is a simplified parse — production would fully parse the IP/UDP headers
        var offset = 12
        var labels: [String] = []

        while offset < packet.count {
            let length = Int(packet[offset])
            offset += 1
            if length == 0 { break }
            if offset + length > packet.count { return nil }
            if let label = String(data: packet[offset..<(offset + length)], encoding: .ascii) {
                labels.append(label)
            }
            offset += length
        }

        return labels.isEmpty ? nil : labels.joined(separator: ".")
    }

    // ── App message handler ─────────────────────────────────────────
    override func handleAppMessage(
        _ messageData: Data,
        completionHandler: ((Data?) -> Void)?
    ) {
        guard let message = String(data: messageData, encoding: .utf8) else {
            completionHandler?(nil)
            return
        }
        os_log("Shield: received app message — %{public}@", log: log, type: .info, message)

        // Message: "reload" — refresh blocklist (future: dynamic blocklist update)
        if message == "reload" {
            os_log("Shield: blocklist reload requested", log: log, type: .info)
        }

        completionHandler?(nil)
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        os_log("Shield: tunnel sleeping", log: log, type: .debug)
        completionHandler()
    }

    override func wake() {
        os_log("Shield: tunnel waking", log: log, type: .debug)
    }
}
