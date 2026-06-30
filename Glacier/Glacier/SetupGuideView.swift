// SetupGuideView.swift
// Shield — Setup guide sheet

import SwiftUI

struct SetupGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlatform: Platform?
    @State private var copiedIndex: Int?

    var body: some View {
        NavigationStack {
            ZStack {
                DS.chalk.ignoresSafeArea()

                if let platform = selectedPlatform {
                    StepsView(
                        platform: platform,
                        copiedIndex: $copiedIndex,
                        onCopy: copyText,
                        onBack: { selectedPlatform = nil }
                    )
                } else {
                    PlatformGrid(onSelect: { selectedPlatform = $0 })
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        if selectedPlatform != nil {
                            Button {
                                selectedPlatform = nil
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(DS.crimson)
                            }
                        }
                        Text(selectedPlatform?.name.uppercased() ?? "SETUP GUIDE")
                            .font(DS.label(12))
                            .tracking(2)
                            .foregroundColor(DS.ink)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(DS.sans(14, weight: .medium))
                        .foregroundColor(DS.crimson)
                }
            }
            .toolbarBackground(DS.chalk, for: .navigationBar)
        }
        .preferredColorScheme(.light)
    }

    private func copyText(_ text: String, index: Int) {
        UIPasteboard.general.string = text
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        copiedIndex = index
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if copiedIndex == index { copiedIndex = nil }
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Data Models
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
struct Platform: Identifiable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let steps: [SetupStep]
}

struct SetupStep: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let cmd: String?
}

let platforms: [Platform] = [
    Platform(
        id: "ios",
        name: "iPhone / iPad",
        icon: "📱",
        description: "System-wide DNS + Safari extension",
        steps: [
            SetupStep(title: "Open Settings",
                      detail: "Go to Settings → General → VPN & Device Management.",
                      cmd: nil),
            SetupStep(title: "Allow VPN",
                      detail: "When Shield prompts for VPN permission, tap Allow. This creates the local DNS tunnel.",
                      cmd: nil),
            SetupStep(title: "Enable Safari Extension",
                      detail: "Go to Settings → Safari → Extensions → Shield → turn on.",
                      cmd: nil),
            SetupStep(title: "Enable Content Blocker",
                      detail: "Settings → Safari → Content Blockers → Shield → toggle On.",
                      cmd: nil),
            SetupStep(title: "Activate Shield",
                      detail: "Return to Shield and tap ACTIVATE SHIELD. All ads blocked system-wide.",
                      cmd: nil),
        ]
    ),
    Platform(
        id: "dns",
        name: "Encrypted DNS Only",
        icon: "🔒",
        description: "Fallback: AdGuard DNS without VPN",
        steps: [
            SetupStep(title: "Open Settings",
                      detail: "Go to Settings → Wi-Fi → tap your network → Configure DNS.",
                      cmd: nil),
            SetupStep(title: "Set Manual DNS",
                      detail: "Select Manual. Add the AdGuard DNS servers below.",
                      cmd: nil),
            SetupStep(title: "Primary DNS",
                      detail: "AdGuard primary (blocks ads + trackers):",
                      cmd: "94.140.14.14"),
            SetupStep(title: "Secondary DNS",
                      detail: "AdGuard secondary (fallback):",
                      cmd: "94.140.15.15"),
            SetupStep(title: "Save",
                      detail: "Tap Save. DNS-level blocking is now active for all apps on this network.",
                      cmd: nil),
        ]
    ),
    Platform(
        id: "doh",
        name: "DNS-over-HTTPS",
        icon: "🛡",
        description: "Encrypted DNS that can't be snooped",
        steps: [
            SetupStep(title: "Download profile",
                      detail: "Open Safari and visit the AdGuard DNS-over-HTTPS profile page.",
                      cmd: "adguard-dns.io/en/public-dns.html"),
            SetupStep(title: "Install profile",
                      detail: "Tap Download Profile → go to Settings → tap the profile → Install.",
                      cmd: nil),
            SetupStep(title: "Done",
                      detail: "All DNS queries are now encrypted and filtered. Works in every app, not just Safari.",
                      cmd: nil),
        ]
    ),
    Platform(
        id: "safari",
        name: "Safari Only",
        icon: "🧭",
        description: "Quickest option — no VPN needed",
        steps: [
            SetupStep(title: "Enable Content Blocker",
                      detail: "Settings → Safari → Content Blockers → Shield → toggle On.",
                      cmd: nil),
            SetupStep(title: "Verify in Safari",
                      detail: "Open any website. Tap the AA icon in the address bar — you'll see Shield is active.",
                      cmd: nil),
            SetupStep(title: "Upgrade for all apps",
                      detail: "Use ACTIVATE SHIELD in the main screen to add DNS-level blocking for Pinterest, games, and every other app.",
                      cmd: nil),
        ]
    ),
    Platform(
        id: "router",
        name: "Router / Network",
        icon: "📡",
        description: "Protect every device on your Wi-Fi",
        steps: [
            SetupStep(title: "Log into router",
                      detail: "Open your router admin panel — usually at 192.168.1.1 or 192.168.0.1.",
                      cmd: "192.168.1.1"),
            SetupStep(title: "Find DNS settings",
                      detail: "Look under WAN, Internet, or DHCP settings for DNS fields.",
                      cmd: nil),
            SetupStep(title: "Set primary DNS",
                      detail: "Primary AdGuard DNS:",
                      cmd: "94.140.14.14"),
            SetupStep(title: "Set secondary DNS",
                      detail: "Secondary AdGuard DNS:",
                      cmd: "94.140.15.15"),
            SetupStep(title: "Save & reboot",
                      detail: "Save settings and reboot the router. Every device — iPhone, iPad, laptop, TV — is now ad-free on this network.",
                      cmd: nil),
        ]
    ),
]

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Platform Grid
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
struct PlatformGrid: View {
    let onSelect: (Platform) -> Void

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("How do you\nwant to block?")
                        .font(DS.display(34, weight: .black))
                        .foregroundColor(DS.ink)
                        .lineSpacing(2)

                    Text("Choose a method. Shield recommends the full VPN option for Brave-level coverage in every app.")
                        .font(DS.sans(14))
                        .foregroundColor(DS.stone)
                        .lineSpacing(3)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Divider()
                    .background(DS.ink.opacity(0.1))
                    .padding(.horizontal, 24)

                // Grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(platforms) { platform in
                        Button { onSelect(platform) } label: {
                            PlatformCard(platform: platform)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .padding(.top, 24)
        }
    }
}

struct PlatformCard: View {
    let platform: Platform

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(platform.icon)
                .font(.system(size: 30))

            Text(platform.name)
                .font(DS.sans(13, weight: .semibold))
                .foregroundColor(DS.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(platform.description)
                .font(DS.sans(11))
                .foregroundColor(DS.stone)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardStyle(fill: DS.paper, stroke: DS.ink.opacity(0.06))
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Steps View
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
struct StepsView: View {
    let platform: Platform
    @Binding var copiedIndex: Int?
    let onCopy: (String, Int) -> Void
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Platform header
                HStack(spacing: 14) {
                    Text(platform.icon)
                        .font(.system(size: 32))
                        .frame(width: 52, height: 52)
                        .background(DS.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(platform.name)
                            .font(DS.sans(18, weight: .bold))
                            .foregroundColor(DS.ink)
                        Text(platform.description)
                            .font(DS.sans(12))
                            .foregroundColor(DS.stone)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 24)

                Divider()
                    .background(DS.ink.opacity(0.1))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                // Steps
                VStack(spacing: 0) {
                    ForEach(Array(platform.steps.enumerated()), id: \.element.id) { index, step in
                        StepCard(
                            index: index + 1,
                            step: step,
                            isLast: index == platform.steps.count - 1,
                            isCopied: copiedIndex == index,
                            onCopy: { onCopy($0, index) }
                        )
                    }
                }
                .padding(.horizontal, 24)

                // Done card
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(DS.crimson)

                    Text("You're protected.")
                        .font(DS.display(20, weight: .black))
                        .foregroundColor(DS.ink)

                    Text("Shield is blocking ads across \(platform.name).")
                        .font(DS.sans(13))
                        .foregroundColor(DS.stone)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .padding(.horizontal, 20)
                .cardStyle(fill: DS.crimson.opacity(0.04), stroke: DS.crimson.opacity(0.12))
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 48)
            }
        }
    }
}

struct StepCard: View {
    let index: Int
    let step: SetupStep
    let isLast: Bool
    let isCopied: Bool
    let onCopy: (String) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {

            // Step number + connector line
            VStack(spacing: 0) {
                // Number badge
                Text("\(index)")
                    .font(DS.sans(11, weight: .bold))
                    .foregroundColor(DS.chalk)
                    .frame(width: 26, height: 26)
                    .background(DS.crimson)
                    .clipShape(Circle())

                // Connector
                if !isLast {
                    Rectangle()
                        .fill(DS.crimson.opacity(0.2))
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 4)
                }
            }
            .frame(width: 26)

            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(step.title)
                    .font(DS.sans(14, weight: .semibold))
                    .foregroundColor(DS.ink)

                Text(step.detail)
                    .font(DS.sans(13))
                    .foregroundColor(DS.stone)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                if let cmd = step.cmd {
                    HStack(spacing: 10) {
                        Text(cmd)
                            .font(DS.mono(12))
                            .foregroundColor(DS.crimson)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(DS.crimson.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(DS.crimson.opacity(0.15), lineWidth: 0.75)
                            )

                        Button { onCopy(cmd) } label: {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(isCopied ? DS.crimson : DS.stone)
                                .frame(width: 34, height: 34)
                                .background(DS.paper)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                }
            }
            .padding(.bottom, isLast ? 0 : 24)
        }
    }
}

#Preview {
    SetupGuideView()
}
