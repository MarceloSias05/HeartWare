//
//  WatchStepView.swift
//  HearthwareWatch Watch App
//
//  Words only, never numbers. Past the doctor's limit it offers the breathing guide.
//

import SwiftUI
import WatchKit

struct WatchStepView: View {
    @Environment(StepWorkout.self) private var workout
    @State private var breathing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                switch workout.phase {
                case .idle:
                    Text("Start a step from your iPhone")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                case .moving:
                    // Words only: the limit's number stays out of the wrist.
                    Text(workout.overLimit ? "Slow down a little" : "You're doing well").font(.headline)
                    Text(workout.overLimit ? "Rest a moment. Take a breath." : "Stop anytime.")
                        .font(.footnote).foregroundStyle(.secondary)
                    // Past the doctor's limit, the message comes with something to do. No limit, no offer.
                    if workout.overLimit {
                        Button("Breathe", systemImage: "wind") { breathing = true }
                            .tint(watchMint)
                    }
                    Button("End step") { workout.endStep() }
                        .tint(watchMint)
                case .resting:
                    Text("Rest and breathe").font(.headline)
                    Text("Your heart is settling.").font(.footnote).foregroundStyle(.secondary)
                    Button("Done resting") { workout.doneResting() }
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 4)
        }
        .sheet(isPresented: $breathing) { WatchBreathingView() }
    }
}

let watchMint = Color(red: 0, green: 0.76, blue: 0.66)

/// The mint orb, sized for the Watch. Still on its own; only the breathing guide moves it.
struct WatchOrb: View {
    var size: CGFloat = 56
    var expanded = false

    var body: some View {
        Circle()
            .fill(LinearGradient(colors: [Color(red: 0.5, green: 0.9, blue: 0.84), watchMint],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: size, maxHeight: size)
            .scaleEffect(expanded ? 1.0 : 0.65)
            .accessibilityHidden(true)
    }
}

/// About 4 s in, 6 s out, for about a minute. Words and taps, never a count.
/// It only opens during a step, so the workout session keeps the screen on.
struct WatchBreathingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathingIn = false
    /// Switches quickly, while the orb takes the whole breath.
    @State private var wordsIn = false

    var body: some View {
        VStack(spacing: 8) {
            WatchOrb(size: 80, expanded: reduceMotion || breathingIn)
                .opacity(reduceMotion && !breathingIn ? 0.5 : 1)
                .frame(maxHeight: .infinity)
            Text(wordsIn ? "Breathe in" : "Breathe out")
                .font(.title3.bold())
                .contentTransition(.opacity)
                .accessibilityAddTraits(.updatesFrequently)
            Button("Done") { dismiss() }
                .accessibilityHint("Stops the breathing guide")
        }
        .task {
            for _ in 0..<6 {
                await breathe(in: true, 4)
                await breathe(in: false, 6)
                if Task.isCancelled { return }
            }
            dismiss()
        }
    }

    private func breathe(in inhale: Bool, _ seconds: Double) async {
        withAnimation(.easeInOut(duration: seconds)) { breathingIn = inhale }
        withAnimation(.easeOut(duration: 0.3)) { wordsIn = inhale }
        // Different taps so the wrist can tell in from out without looking.
        WKInterfaceDevice.current().play(inhale ? .directionUp : .directionDown)
        AccessibilityNotification.Announcement(inhale ? "Breathe in" : "Breathe out").post()
        try? await Task.sleep(for: .seconds(seconds))
    }
}
