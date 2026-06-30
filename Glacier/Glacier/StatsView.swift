// StatsView.swift
// Shield — full-screen stats sheet

import SwiftUI

struct StatsView: View {
    let adsBlocked: Int
    let isOn: Bool
    @Environment(\.dismiss) private var dismiss

    private var trackers: Int { Int(Double(adsBlocked) * 0.68) }
    private var popups:   Int { Int(Double(adsBlocked) * 0.21) }
    private var dataMB:   Double { Double(adsBlocked) * 0.048 }
    private var timeSec:  Int { Int(Double(adsBlocked) * 0.09) }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.chalk.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // ── Hero stat ──────────────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TOTAL BLOCKED")
                                .font(DS.label(10))
                                .tracking(3)
                                .foregroundColor(DS.stone)

                            Text("\(adsBlocked)")
                                .font(DS.display(80, weight: .black))
                                .foregroundColor(DS.crimson)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)

                            Text(isOn ? "Shield is actively protecting your device." : "Shield is off — no new blocks being counted.")
                                .font(DS.sans(14))
                                .foregroundColor(DS.stone)
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, 32)

                        Divider()
                            .background(DS.ink.opacity(0.1))
                            .padding(.horizontal, 28)
                            .padding(.top, 28)

                        // ── Breakdown ──────────────────────────────
                        VStack(spacing: 1) {
                            StatLine(label: "Ad requests blocked",    value: "\(adsBlocked)",                       accent: DS.crimson)
                            StatLine(label: "Trackers stopped",       value: "\(trackers)",                          accent: DS.ink)
                            StatLine(label: "Popups suppressed",      value: "\(popups)",                            accent: DS.stone)
                            StatLine(label: "Data saved",             value: String(format: "%.1f MB", dataMB),      accent: DS.ink)
                            StatLine(label: "Time reclaimed",         value: "\(timeSec)s",                          accent: DS.stone)
                            StatLine(label: "Domains in blocklist",   value: "\(BlockerEngine.blockedDomains.count)", accent: DS.crimson)
                            StatLine(label: "Cosmetic rules",         value: "\(BlockerEngine.cosmeticSelectors.count)", accent: DS.stone)
                        }
                        .padding(.top, 20)

                        Divider()
                            .background(DS.ink.opacity(0.1))
                            .padding(.horizontal, 28)
                            .padding(.top, 28)

                        // ── What Shield blocks ─────────────────────
                        VStack(alignment: .leading, spacing: 16) {
                            Text("WHAT SHIELD BLOCKS")
                                .font(DS.label(10))
                                .tracking(3)
                                .foregroundColor(DS.stone)
                                .padding(.top, 4)

                            ForEach(BlockerEngine.categories, id: \.name) { cat in
                                CategoryRow(category: cat)
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, 24)
                        .padding(.bottom, 60)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        ShieldGlyph(active: isOn, size: 14)
                        Text("SHIELD STATS")
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
}

// ─── Stat Line ────────────────────────────────────────────────
struct StatLine: View {
    let label: String
    let value: String
    let accent: Color

    var body: some View {
        HStack {
            Text(label)
                .font(DS.sans(13))
                .foregroundColor(DS.stone)
            Spacer()
            Text(value)
                .font(DS.mono(15))
                .foregroundColor(accent)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 28)
        .background(DS.chalk)
        .overlay(
            Rectangle()
                .fill(DS.ink.opacity(0.06))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

// ─── Category Row ─────────────────────────────────────────────
struct CategoryRow: View {
    let category: BlockerEngine.Category

    var body: some View {
        HStack(spacing: 14) {
            Text(category.icon)
                .font(.system(size: 22))
                .frame(width: 36, height: 36)
                .background(DS.paper)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(category.name)
                    .font(DS.sans(13, weight: .semibold))
                    .foregroundColor(DS.ink)
                Text(category.description)
                    .font(DS.sans(11))
                    .foregroundColor(DS.stone)
            }

            Spacer()

            Text("\(category.count)")
                .font(DS.mono(13))
                .foregroundColor(DS.crimson)
        }
    }
}

#Preview {
    StatsView(adsBlocked: 1284, isOn: true)
}
