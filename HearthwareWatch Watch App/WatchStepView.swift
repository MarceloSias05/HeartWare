//
//  WatchStepView.swift
//  HearthwareWatch Watch App
//
//  Words only, never numbers. The orb breathes like on the iPhone and stays still
//  with Reduce Motion.
//

import SwiftUI

struct WatchStepView: View {
    @Environment(StepWorkout.self) private var workout

    var body: some View {
        VStack(spacing: 8) {
            WatchOrb()
            switch workout.phase {
            case .idle:
                Text("Start a step from your iPhone")
                    .font(.headline)
                    .multilineTextAlignment(.center)
            case .moving:
                Text("You're doing well").font(.headline)
                Text("Stop anytime.").font(.footnote).foregroundStyle(.secondary)
                Button("End step") { workout.endStep() }
                    .tint(Color(red: 0, green: 0.76, blue: 0.66))
            case .resting:
                Text("Rest and breathe").font(.headline)
                Text("Your heart is settling.").font(.footnote).foregroundStyle(.secondary)
                Button("Done resting") { workout.doneResting() }
            }
        }
        .padding(.horizontal, 4)
    }
}

/// The brand orb, sized for the Watch.
struct WatchOrb: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathing = false

    var body: some View {
        Circle()
            .fill(LinearGradient(colors: [Color(red: 0.5, green: 0.9, blue: 0.84), Color(red: 0, green: 0.76, blue: 0.66)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 56, height: 56)
            .scaleEffect(breathing ? 1.06 : 0.94)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) { breathing = true }
            }
            .accessibilityHidden(true)
    }
}
