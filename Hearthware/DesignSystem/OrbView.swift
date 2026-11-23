//
//  OrbView.swift
//  Hearthware
//
//  The orb breathes slowly (5 s in, 5 s out). It is not synced to the real
//  heart rate on purpose. Teal when calm, amber when things feel hard; never
//  red, which is kept for help and emergencies. With `pulses`, a light tap
//  marks each inhale. With Reduce Motion it stays still, without taps, and
//  only the colour and the words carry the state.
//

import SwiftUI

struct OrbView: View {
    var calm: Bool = true
    var size: CGFloat = 140
    /// A soft haptic at the start of each breath. Only while a step is in progress.
    var pulses: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathing = false
    @State private var breaths = 0

    private static let halfBreath: Double = 5

    private var color: Color { calm ? .hwMint : .hwAmber }
    private var light: Color { calm ? Color(red: 0.5, green: 0.9, blue: 0.84) : Color(red: 1.0, green: 0.82, blue: 0.54) }

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(breathing ? 0.5 : 0.25))
                .frame(width: size * 1.35, height: size * 1.35)
                .blur(radius: size * 0.2)
                .scaleEffect(breathing ? 1.12 : 0.92)
            Circle()
                .fill(LinearGradient(colors: [light, color], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
            Circle()
                .fill(.white.opacity(0.6))
                .frame(width: size * 0.4, height: size * 0.4)
                .blur(radius: size * 0.08)
                .offset(x: -size * 0.15, y: -size * 0.18)
        }
        .scaleEffect(breathing ? 1.08 : 0.92)
        .animation(.easeInOut(duration: 1.2), value: calm)
        .onAppear { startBreathing() }
        .task(id: pulses && !reduceMotion) { await pulse() }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: breaths)
        .accessibilityHidden(true)
    }

    private func startBreathing() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: Self.halfBreath).repeatForever(autoreverses: true)) {
            breathing = true
        }
    }

    /// One tap per full breath, in step with the inhale that starts on appear.
    private func pulse() async {
        guard pulses, !reduceMotion else { return }
        while !Task.isCancelled {
            breaths += 1
            try? await Task.sleep(for: .seconds(Self.halfBreath * 2))
        }
    }
}

#Preview {
    HStack(spacing: 40) {
        OrbView(pulses: true)
        OrbView(calm: false, size: 100)
    }
}
