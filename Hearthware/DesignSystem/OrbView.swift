//
//  OrbView.swift
//  Hearthware
//
//  The mint orb. Still on its own: it only moves inside the breathing guide, where
//  `expanded` follows the breath. Outside the guide it is the brand mark in onboarding.
//  Never red, which is kept for help and emergencies.
//

import SwiftUI

struct OrbView: View {
    var size: CGFloat = 140
    /// Full (breathing in) or small (breathing out). Animated by `BreathingView`.
    var expanded = false

    private static let light = Color(red: 0.5, green: 0.9, blue: 0.84)

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.hwMint.opacity(expanded ? 0.5 : 0.25))
                .frame(width: size * 1.35, height: size * 1.35)
                .blur(radius: size * 0.2)
                .scaleEffect(expanded ? 1.12 : 0.92)
            Circle()
                .fill(LinearGradient(colors: [Self.light, .hwMint], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
            Circle()
                .fill(.white.opacity(0.6))
                .frame(width: size * 0.4, height: size * 0.4)
                .blur(radius: size * 0.08)
                .offset(x: -size * 0.15, y: -size * 0.18)
        }
        .scaleEffect(expanded ? 1.0 : 0.7)
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 40) {
        OrbView(size: 100)
        OrbView(size: 100, expanded: true)
    }
}
