//
//  OrbView.swift
//  Hearthware
//
//  The orb breathes slowly (about 4 s in, 6 s out). It is not synced to the
//  real heart rate on purpose. With Reduce Motion it stays still and only the
//  colour and the words carry the state.
//

import SwiftUI

struct OrbView: View {
    var calm: Bool = true
    var size: CGFloat = 140

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathing = false

    private var color: Color { calm ? .hwMint : .hwAmber }
    private var light: Color { calm ? Color(red: 0.5, green: 0.9, blue: 0.84) : Color(red: 1.0, green: 0.82, blue: 0.54) }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.35))
                .frame(width: size * 1.35, height: size * 1.35)
                .blur(radius: size * 0.2)
            Circle()
                .fill(LinearGradient(colors: [light, color], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
            Circle()
                .fill(.white.opacity(0.6))
                .frame(width: size * 0.4, height: size * 0.4)
                .blur(radius: size * 0.08)
                .offset(x: -size * 0.15, y: -size * 0.18)
        }
        .scaleEffect(breathing ? 1.06 : 0.94)
        .onAppear { startBreathing() }
        .accessibilityHidden(true)
    }

    private func startBreathing() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
            breathing = true
        }
    }
}

#Preview {
    HStack(spacing: 40) {
        OrbView()
        OrbView(calm: false, size: 100)
    }
}
