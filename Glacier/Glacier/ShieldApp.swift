// ShieldApp.swift
// Shield — Brutal Ad Blocker for iOS
//
// ARCHITECTURE:
//   1. NEPacketTunnelProvider   — intercepts ALL DNS queries system-wide
//   2. Safari Content Blocker  — cosmetic hiding + URL blocking in Safari/WebKit
//   3. AdGuard DNS (encrypted) — upstream resolver that drops ad/tracker domains
//
// Design language: Second Society — chalk cream, crimson, editorial boldness.

import SwiftUI
import NetworkExtension

@main
struct ShieldApp: App {
    @StateObject private var vpnManager = VPNManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vpnManager)
                .preferredColorScheme(.light) // Second Society is light-mode-first
                .onAppear {
                    vpnManager.loadPreferences()
                }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// VPN MANAGER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class VPNManager: ObservableObject {
    static let shared = VPNManager()

    @Published var isConnected  = false
    @Published var isConnecting = false
    @Published var status: NEVPNStatus = .disconnected

    private var manager: NETunnelProviderManager?

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(vpnStatusDidChange),
            name: .NEVPNStatusDidChange,
            object: nil
        )
    }

    func loadPreferences() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let self else { return }
            if let existing = managers?.first {
                self.manager = existing
            } else {
                self.createNewManager()
            }
            DispatchQueue.main.async {
                self.status      = self.manager?.connection.status ?? .disconnected
                self.isConnected = self.status == .connected
            }
        }
    }

    private func createNewManager() {
        let manager = NETunnelProviderManager()
        let proto   = NETunnelProviderProtocol()

        proto.providerBundleIdentifier = "com.shield.app.PacketTunnel"
        proto.serverAddress = "Shield Local Tunnel"
        proto.providerConfiguration = [
            // AdGuard DNS-over-HTTPS (Encrypted) — primary + secondary
            "dnsDoH":      "https://dns.adguard-dns.com/dns-query",
            "dns":         "94.140.14.14",
            "dnsSecondary":"94.140.15.15",
        ]

        manager.protocolConfiguration = proto
        manager.localizedDescription   = "Shield"
        manager.isEnabled              = true

        manager.saveToPreferences { [weak self] error in
            if let error { print("Shield: VPN save error — \(error)"); return }
            self?.manager = manager
        }
    }

    func connect() {
        guard let manager else { loadPreferences(); return }
        isConnecting = true
        do    { try manager.connection.startVPNTunnel() }
        catch { print("Shield: VPN start error — \(error)"); isConnecting = false }
    }

    func disconnect() { manager?.connection.stopVPNTunnel() }

    func toggle() { isConnected ? disconnect() : connect() }

    @objc private func vpnStatusDidChange(_ notification: Notification) {
        guard let connection = notification.object as? NEVPNConnection else { return }
        DispatchQueue.main.async {
            self.status      = connection.status
            self.isConnected = connection.status == .connected
            self.isConnecting = connection.status == .connecting
        }
    }
}
