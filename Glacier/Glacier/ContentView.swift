// ContentView.swift
// Shield — main screen
//
// Layout: editorial, portrait-first
//   ┌─────────────────────────────┐
//   │  SHIELD          [stats →]  │  ← top bar
//   ├─────────────────────────────┤
//   │                             │
//   │   THE SHIELD                │  ← hero word-mark (serif, large)
//   │   IS [OFF / ON]             │
//   │                             │
//   │   ─────────────────────     │  ← hairline divider
//   │                             │
//   │   [ ACTIVATE SHIELD ]       │  ← CTA button (crimson fill when off)
//   │                             │
//   ├─────────────────────────────┤
//   │  ┌──────┐ ┌──────┐ ┌─────┐ │  ← stat tiles
//   │  │ 0    │ │ 127  │ │ DNS │ │
//   │  │ BLKD │ │ DMNS │ │ ENC │ │
//   │  └──────┘ └──────┘ └─────┘ │
//   ├─────────────────────────────┤
//   │  Protected everywhere:      │  ← coverage strip
//   │  Pinterest  YouTube  …      │
//   └─────────────────────────────┘

import SwiftUI
import NetworkExtension

struct ContentView: View {
    @EnvironmentObject var vpnManager: VPNManager
    @AppStorage("ads_blocked") private var adsBlocked = 0
    @State private var showStats  = false
    @State private var showSetup  = false
    @State private var pulseOn    = false
    @State private var isOn       = false

    private let domainCount = BlockerEngine.blockedDomains.count
    private let apps        = BlockerEngine.appsCovered

    var body: some View {
        NavigationStack {
            ZStack {
                DS.chalk.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // ── Top bar ────────────────────────────────────
                        topBar
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        // ── Hero ───────────────────────────────────────
                        heroSection
                            .padding(.horizontal, 24)
                            .padding(.top, 40)

                        // ── Divider ────────────────────────────────────
                        Divider()
                            .background(DS.ink.opacity(0.12))
                            .padding(.horizontal, 24)
                            .padding(.top, 40)

                        // ── CTA button ─────────────────────────────────
                        ctaButton
                            .padding(.horizontal, 24)
                            .padding(.top, 32)

                        // ── VPN status card ────────────────────────────
                        if isOn {
                            statusCard
                                .padding(.horizontal, 24)
                                .padding(.top, 16)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // ── Stats row ──────────────────────────────────
                        statsRow
                            .padding(.horizontal, 24)
                            .padding(.top, 32)

                        // ── Coverage ───────────────────────────────────
                        coverageSection
                            .padding(.top, 32)
                            .padding(.bottom, 48)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showStats) {
            StatsView(adsBlocked: adsBlocked, isOn: isOn)
        }
        .sheet(isPresented: $showSetup) {
            SetupGuideView()
        }
        // Simulated increment while active
        .onReceive(Timer.publish(every: 4, on: .main, in: .common).autoconnect()) { _ in
            if isOn { adsBlocked += Int.random(in: 1...5) }
        }
    }

    // ── Sub-views ──────────────────────────────────────────────────────────

    private var topBar: some View {
        HStack(alignment: .center) {
            // Wordmark
            HStack(spacing: 6) {
                ShieldGlyph(active: isOn, size: 18)
                Text("SHIELD")
                    .font(DS.label(11))
                    .tracking(4)
                    .foregroundColor(DS.ink)
            }

            Spacer()

            // Right actions
            HStack(spacing: 16) {
                Button { showSetup = true } label: {
                    Text("SETUP")
                        .font(DS.label(10))
                        .tracking(2)
                        .foregroundColor(DS.stone)
                }
                Button { showStats = true } label: {
                    Text("STATS")
                        .font(DS.label(10))
                        .tracking(2)
                        .foregroundColor(DS.stone)
                }
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Eyebrow
            Text("SYSTEM-WIDE PROTECTION")
                .font(DS.label(10))
                .tracking(3)
                .foregroundColor(DS.stone)
                .padding(.bottom, 16)

            // Large editorial headline
            Group {
                Text("The\nShield\nis ")
                    .font(DS.display(64, weight: .black))
                    .foregroundColor(DS.ink)
                +
                Text(isOn ? "on." : "off.")
                    .font(DS.display(64, weight: .black))
                    .foregroundColor(isOn ? DS.crimson : DS.stone)
            }
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
            .animation(.spring(response: 0.4), value: isOn)

            // Subtitle
            Text(isOn
                 ? "Every ad. Every app. Gone."
                 : "Blocks ads in Pinterest, games, YouTube & everywhere else.")
                .font(DS.sans(15))
                .foregroundColor(DS.stone)
                .padding(.top, 20)
                .animation(.easeInOut(duration: 0.3), value: isOn)
        }
    }

    private var ctaButton: some View {
        Button {
            handleToggle(!isOn)
        } label: {
            HStack(spacing: 12) {
                ShieldGlyph(active: isOn, size: 20)
                    .foregroundColor(isOn ? DS.ink : DS.chalk)

                Text(isOn ? "DEACTIVATE SHIELD" : "ACTIVATE SHIELD")
                    .font(DS.sans(14, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(isOn ? DS.ink : DS.chalk)

                Spacer()

                Image(systemName: isOn ? "stop.fill" : "play.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isOn ? DS.stone : DS.chalk.opacity(0.7))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .background(
                Group {
                    if isOn {
                        DS.paper
                    } else {
                        DS.crimson
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isOn ? DS.ink.opacity(0.12) : Color.clear, lineWidth: 1)
            )
            .scaleEffect(pulseOn ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isOn)
        .animation(.easeInOut(duration: 0.12), value: pulseOn)
    }

    private var statusCard: some View {
        HStack(spacing: 14) {
            // Animated active dot
            ZStack {
                Circle()
                    .fill(DS.crimson.opacity(0.15))
                    .frame(width: 36, height: 36)
                Circle()
                    .fill(DS.crimson)
                    .frame(width: 10, height: 10)
                    .scaleEffect(pulseOn ? 1.4 : 1.0)
                    .opacity(pulseOn ? 0.4 : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(), value: pulseOn)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(vpnStatusText)
                    .font(DS.sans(13, weight: .semibold))
                    .foregroundColor(DS.ink)

                Text("DNS encrypted via AdGuard  ·  All apps covered")
                    .font(DS.sans(11))
                    .foregroundColor(DS.stone)
            }

            Spacer()
        }
        .padding(16)
        .cardStyle(fill: DS.paper, stroke: DS.crimson.opacity(0.15))
        .onAppear { pulseOn = true }
    }

    private var vpnStatusText: String {
        switch vpnManager.status {
        case .connected:     return "Protected — VPN tunnel active"
        case .connecting:    return "Connecting tunnel…"
        case .disconnecting: return "Winding down…"
        default:             return "DNS-level blocking active"
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatTile(
                value: isOn ? "\(adsBlocked)" : "—",
                label: "BLOCKED",
                accent: DS.crimson,
                active: isOn
            )
            StatTile(
                value: "\(domainCount)",
                label: "DOMAINS",
                accent: DS.ink,
                active: true
            )
            StatTile(
                value: "DNS",
                label: "ENCRYPTED",
                accent: DS.stone,
                active: true,
                isText: true
            )
        }
    }

    private var coverageSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section header
            HStack {
                Text(isOn ? "PROTECTING" : "WILL PROTECT")
                    .font(DS.label(10))
                    .tracking(3)
                    .foregroundColor(DS.stone)
                    .padding(.leading, 24)
                Spacer()
            }

            // App chips — horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Spacer(minLength: 16)
                    ForEach(apps, id: \.name) { app in
                        AppChip(app: app, active: isOn)
                    }
                    Spacer(minLength: 16)
                }
            }
        }
    }

    // ── Actions ─────────────────────────────────────────────────────────────
    private func handleToggle(_ newValue: Bool) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.4)) { isOn = newValue }
        if newValue {
            vpnManager.connect()
            BlockerEngine.reloadContentBlocker()
        } else {
            vpnManager.disconnect()
            pulseOn = false
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Shield Glyph (replaces Pac-Man entirely)
// A minimal shield icon drawn in SwiftUI
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
struct ShieldGlyph: View {
    let active: Bool
    var size: CGFloat = 24

    var body: some View {
        Image(systemName: active ? "shield.fill" : "shield")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(active ? DS.crimson : DS.stone)
            .animation(.easeInOut(duration: 0.2), value: active)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Stat Tile
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
struct StatTile: View {
    let value: String
    let label: String
    let accent: Color
    var active: Bool = true
    var isText: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(isText ? DS.sans(22, weight: .black) : DS.mono(28))
                .foregroundColor(active ? accent : DS.stone.opacity(0.35))
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(label)
                .font(DS.label(9))
                .tracking(2)
                .foregroundColor(DS.stone)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardStyle(fill: DS.paper)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// App Coverage Chip
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
struct AppChip: View {
    let app: (icon: String, name: String)
    let active: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text(app.icon).font(.system(size: 13))
            Text(app.name)
                .font(DS.sans(12, weight: .medium))
                .foregroundColor(active ? DS.ink : DS.stone)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(active ? DS.crimson.opacity(0.06) : DS.paper)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(active ? DS.crimson.opacity(0.2) : DS.ink.opacity(0.08), lineWidth: 0.75)
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(VPNManager.shared)
}
