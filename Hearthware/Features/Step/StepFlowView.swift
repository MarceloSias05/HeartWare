//
//  StepFlowView.swift
//  Hearthware
//
//  Before → (ask your doctor, for big steps) → on your Watch, or with you on the iPhone
//  when there is no Watch → after → what your body did.
//

import SwiftUI

struct StepFlowView: View {
    let idea: StepIdea

    @Environment(AppModel.self) private var model
    @Environment(WatchLink.self) private var watchLink
    @Environment(\.dismiss) private var dismiss

    enum Phase { case before, askDoctor, onWatch, withYou, after, result }

    @State private var phase: Phase = .before
    @State private var before: Feeling = .nervous
    @State private var after: Feeling = .calm
    @State private var noteBefore = ""
    @State private var noteAfter = ""
    @State private var record: StepRecord?
    @State private var watchResult: WatchResult?
    @State private var showingBreath = false

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .before: beforeView
                case .askDoctor: askDoctorView
                case .onWatch: OnWatchView { watchLink.cancel(); phase = .after }
                case .withYou: WithYouView { phase = .after }
                case .after: afterView
                case .result: resultView
                }
            }
            .animation(.default, value: phase)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if phase != .result {
                        Button("Close", systemImage: "xmark") { dismiss() }
                    }
                }
                // Optional, never forced: a minute of breathing before starting.
                ToolbarItem(placement: .topBarTrailing) {
                    if phase == .before {
                        Button("Breathe first") { showingBreath = true }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if phase == .result {
                        Button("Done", systemImage: "checkmark") { dismiss() }
                            .buttonStyle(.glassProminent)
                    }
                }
            }
        }
        .interactiveDismissDisabled(phase == .withYou || phase == .onWatch)
        .sheet(isPresented: $showingBreath) { BreathingView() }
        .onAppear {
            watchLink.onResult = { result in
                watchResult = result
                if phase == .onWatch { phase = .after }
            }
        }
        .onDisappear {
            if phase == .onWatch { watchLink.cancel() }
            watchLink.onResult = nil
        }
    }

    /// Runs the step on the Watch when it can, otherwise on the iPhone.
    private func begin() {
        Task { phase = await watchLink.start(title: idea.title) ? .onWatch : .withYou }
    }

    // MARK: Before

    private var beforeView: some View {
        FeelingPage(
            eyebrow: idea.title,
            question: "How do you feel about it?",
            footnote: "\(idea.hint)\nThere is no wrong answer. Feeling scared is normal.",
            buttonTitle: watchLink.canUseWatch ? "Start on Apple Watch" : "Start your step",
            feeling: $before,
            note: $noteBefore,
            action: { if idea.bigStep { phase = .askDoctor } else { begin() } }
        )
    }

    // MARK: Ask your doctor

    private var askDoctorView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // How they said they feel about it, on its colour, with the words.
            VStack(spacing: 8) {
                FeelingFaceBadge(feeling: before)
                Text("A big step").font(.title2.bold())
                Text(idea.title)
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(Color(white: 0.12))
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(FeelingFaceBadge.color(before), in: .rect(cornerRadius: 28))
            .accessibilityElement(children: .combine)
            Text("Ask your\ndoctor first")
                .font(.largeTitle.bold())
                .padding(.top, 28)
            Text("This is a big step after a heart problem. A quick check with your doctor will help you feel sure.")
                .foregroundStyle(Color.hwSecondary)
                .padding(.top, 10)
            Spacer(minLength: 24)
            VStack(spacing: 12) {
                Button("My doctor said it's OK") { begin() }
                    .buttonStyle(.pill)
                Button("Choose a gentler step") { dismiss() }
                    .buttonStyle(.pillSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: After

    private var afterView: some View {
        FeelingPage(
            eyebrow: "After: \(idea.title)",
            question: "How did it feel?",
            buttonTitle: "See what your body did",
            feeling: $after,
            note: $noteAfter,
            action: {
                record = model.log(title: idea.title, before: before, after: after, watch: watchResult,
                                   noteBefore: noteBefore, noteAfter: noteAfter)
                phase = .result
            }
        )
    }

    // MARK: Result

    private var resultView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(after.rawValue < before.rawValue ? "You did it" : "You showed up")
                    .font(.largeTitle.bold())
                // How they felt after, as the face on its colour; both feelings in words.
                VStack(spacing: 16) {
                    FeelingFaceBadge(feeling: after)
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline) {
                            feelingWords("Before", before, .leading)
                            Spacer()
                            Image(systemName: "arrow.right").accessibilityHidden(true)
                            Spacer()
                            feelingWords("After", after, .trailing)
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            feelingWords("Before", before, .leading)
                            feelingWords("After", after, .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .foregroundStyle(Color(white: 0.12))
                .padding(20)
                .background(FeelingFaceBadge.color(after), in: .rect(cornerRadius: 28))
                .accessibilityElement(children: .combine)
                .padding(.top, 20)

                Text("What your heart did")
                    .font(.title3.bold())
                    .padding(.top, 28)
                if let record {
                    Text(model.explanation(for: record))
                        .foregroundStyle(Color.hwSecondary)
                        .padding(.top, 8)
                }
                Text("Next time")
                    .font(.title3.bold())
                    .padding(.top, 24)
                Text(model.todayStep.title)
                    .foregroundStyle(Color.hwSecondary)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)
        }
        .safeAreaInset(edge: .bottom) {
            Button("Save to my story") { dismiss() }
                .buttonStyle(.pill)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
    }
}

extension StepFlowView {
    fileprivate func feelingWords(_ label: String, _ feeling: Feeling, _ alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(label).font(.subheadline.weight(.semibold)).opacity(0.75)
            Text(feeling.title).font(.title3.bold())
        }
    }
}

/// The feeling face, sized for a card. Its background colour comes from `color(_:)`.
struct FeelingFaceBadge: View {
    let feeling: Feeling
    static func level(_ f: Feeling) -> Double { Double(Feeling.veryScared.rawValue - f.rawValue) }
    static func color(_ f: Feeling) -> Color { FeelingPalette.color(at: level(f)) }

    var body: some View {
        FeelingFace(calmness: Self.level(feeling) / 3)
            .scaleEffect(0.5)
            .frame(width: 120, height: 84)
            .padding(.vertical, 8)
            .accessibilityHidden(true)
    }
}

/// While the step happens on the Watch. "End step here" is the way out if the Watch stops answering.
struct OnWatchView: View {
    let onEndHere: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            // Still on purpose: the step is on the wrist, nothing to do here.
            Image(systemName: "applewatch")
                .font(.system(size: 96, weight: .light))
                .foregroundStyle(Color.hwSecondary)
                .accessibilityHidden(true)
            Text("Follow your Watch")
                .font(.title.bold())
                .padding(.top, 24)
            Text("It keeps you company while you move. Tap End step on your wrist when you're done.")
                .foregroundStyle(Color.hwSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button("End step here", action: onEndHere)
                .buttonStyle(.pillSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .accessibilityElement(children: .contain)
    }
}

/// The step on the iPhone alone, when there is no Watch to run it.
struct WithYouView: View {
    let onEnd: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "figure.walk")
                .font(.system(size: 96, weight: .light))
                .foregroundStyle(Color.hwSecondary)
                .accessibilityHidden(true)
            Text("You're doing well")
                .font(.title.bold())
                .padding(.top, 24)
            Text("Take it at your own pace. Stop anytime.")
                .foregroundStyle(Color.hwSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button("End step", action: onEnd)
                .buttonStyle(.pill)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    StepFlowView(idea: Goal.stairs.steps[1])
        .environment(AppModel(container: .empty))
        .environment(WatchLink())
}
