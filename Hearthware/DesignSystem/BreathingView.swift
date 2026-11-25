//
//  BreathingView.swift
//  Hearthware
//
//  A short breathing guide: about 4 s in, 6 s out, for about a minute, then it closes.
//  Words only, never a count or a timer. A soft tap starts each breath in and out.
//  With Reduce Motion the orb doesn't grow; it fades and the words still change.
//  Opens as a sheet; "Done" stops it at any time. Not medical advice: no claims.
//

import SwiftUI

struct BreathingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The orb follows `breath` slowly; the words switch quickly so they never overlap.
    @State private var breath: Breath = .out
    @State private var words: Breath = .out

    enum Breath { case `in`, out
        var words: String { self == .in ? "Breathe in" : "Breathe out" }
    }

    /// Seconds in and out, and how many breaths: about a minute in all.
    static let inhale: Double = 4, exhale: Double = 6, breaths = 6

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 16)
            OrbView(size: 160, expanded: reduceMotion || breath == .in)
                .opacity(reduceMotion && breath == .out ? 0.5 : 1)
            Text(words.words)
                .font(.title.bold())
                .contentTransition(.opacity)
                .accessibilityAddTraits(.updatesFrequently)
            Spacer(minLength: 16)
            Button("Done") { dismiss() }
                .buttonStyle(.pill)
                .accessibilityHint("Stops the breathing guide")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .padding(.top, 24)
        .frame(maxWidth: .infinity)
        // A firmer tap to breathe in, a lighter one to breathe out.
        .sensoryFeedback(trigger: words) { _, now in
            .impact(flexibility: .soft, intensity: now == .in ? 0.8 : 0.4)
        }
        .task { await guide() }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        // Solid, so the black/white "Done" pill keeps its full contrast (glass washes it to grey).
        .presentationBackground(Color(uiColor: .systemBackground))
    }

    private func guide() async {
        for _ in 0..<Self.breaths {
            await step(.in, Self.inhale)
            await step(.out, Self.exhale)
            if Task.isCancelled { return }
        }
        dismiss()
    }

    private func step(_ next: Breath, _ seconds: Double) async {
        withAnimation(.easeInOut(duration: seconds)) { breath = next }
        withAnimation(.easeOut(duration: 0.3)) { words = next }
        AccessibilityNotification.Announcement(next.words).post()
        try? await Task.sleep(for: .seconds(seconds))
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) { BreathingView() }
}
