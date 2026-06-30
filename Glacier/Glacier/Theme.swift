// Theme.swift
// Second Society design language for Shield
//
// Palette:
//   Chalk  #F0EDE6  — background, warm off-white
//   Ink    #1A1A18  — primary text, near-black
//   Crimson #B01E28 — accent, action, "on" state
//   Stone  #8A8680  — muted text, labels
//   Paper  #E6E2DA  — surface cards, dividers

import SwiftUI

enum DS {
    // ── Colors ─────────────────────────────────────────────────
    static let chalk   = Color(hex: "F0EDE6")
    static let ink     = Color(hex: "1A1A18")
    static let crimson = Color(hex: "B01E28")
    static let stone   = Color(hex: "8A8680")
    static let paper   = Color(hex: "E6E2DA")
    static let white   = Color.white

    // ── Typography ─────────────────────────────────────────────
    // Display: bold serif (Georgia fallback, use .serif design)
    static func display(_ size: CGFloat, weight: Font.Weight = .black) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    // Body / UI: clean sans
    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    // Mono: stats / numbers
    static func mono(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    // Eyebrow / label caps
    static func label(_ size: CGFloat = 10) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }
}

// ── Convenience hex init ────────────────────────────────────────
extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        self.init(
            red:   Double((int >> 16) & 0xFF) / 255,
            green: Double((int >>  8) & 0xFF) / 255,
            blue:  Double( int        & 0xFF) / 255
        )
    }
}

// ── Reusable card modifier ──────────────────────────────────────
struct CardStyle: ViewModifier {
    var fill: Color = DS.paper
    var stroke: Color = .clear
    var radius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(stroke, lineWidth: 0.75)
            )
    }
}

extension View {
    func cardStyle(fill: Color = DS.paper, stroke: Color = .clear, radius: CGFloat = 16) -> some View {
        modifier(CardStyle(fill: fill, stroke: stroke, radius: radius))
    }
}
