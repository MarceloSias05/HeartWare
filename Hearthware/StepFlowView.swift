//
//  StepFlowView.swift
//  Hearthware
//
//  Before → (ask your doctor, for big steps) → with you → after → what your body did.
//  "With you" stands in for the Apple Watch until the Watch app is added.
//

import SwiftUI

struct StepFlowView: View {
    let idea: StepIdea

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    enum Phase { case before, askDoctor, withYou, after, result }

    @State private var phase: Phase = .before
    @State private var before: Feeling = .nervous
    @State private var after: Feeling = .calm
    @State private var record: StepRecord?

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .before: beforeView
                case .askDoctor: askDoctorView
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
                ToolbarItem(placement: .topBarTrailing) {
                    if phase == .result {
                        Button("Done", systemImage: "checkmark") { dismiss() }
                            .buttonStyle(.glassProminent)
                    }
                }
            }
        }
        .interactiveDismissDisabled(phase == .withYou)
    }

    // MARK: Before

    private var beforeView: some View {
        QuestionPage(
            step: "Your step",
            title: idea.title,
            subtitle: idea.hint,
            footnote: "There is no wrong answer. Feeling scared is normal.",
            buttonTitle: "Start on Apple Watch",
            action: { phase = idea.bigStep ? .askDoctor : .withYou }
        ) {
            Text("How do you feel about it?")
                .font(.title3.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)
            ForEach(Feeling.allCases) { feeling in
                ChoiceRow(title: feeling.title, selected: before == feeling) { before = feeling }
            }
        }
    }

    // MARK: Ask your doctor

    private var askDoctorView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Container {
                VStack(spacing: 12) {
                    OrbView(calm: false, size: 110)
                        .padding(.vertical, 20)
                    Text("A big step").font(.title2.bold())
                    Text(idea.title).foregroundStyle(Color.hwSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            Text("Ask your\ndoctor first")
                .font(.largeTitle.bold())
                .padding(.top, 28)
            Text("This is a big step after a heart problem. A quick check with your doctor will help you feel sure.")
                .foregroundStyle(Color.hwSecondary)
                .padding(.top, 10)
            Spacer(minLength: 24)
            VStack(spacing: 12) {
                Button("My doctor said it's OK") { phase = .withYou }
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
        QuestionPage(
            step: "After your step",
            title: "How did it feel?",
            subtitle: idea.title,
            footnote: nil,
            buttonTitle: "See what your body did",
            action: {
                record = model.log(title: idea.title, before: before, after: after)
                phase = .result
            }
        ) {
            ForEach(Feeling.allCases) { feeling in
                ChoiceRow(title: feeling.title, selected: after == feeling) { after = feeling }
            }
        }
    }

    // MARK: Result

    private var resultView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(after.rawValue < before.rawValue ? "You did it" : "You showed up")
                    .font(.largeTitle.bold())
                Container {
                    VStack(spacing: 16) {
                        OrbView(calm: after.rawValue <= Feeling.littleNervous.rawValue, size: 92)
                            .padding(.vertical, 16)
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Before").font(.subheadline).foregroundStyle(Color.hwSecondary)
                                Text(before.title).font(.title3.bold())
                            }
                            Spacer()
                            Image(systemName: "arrow.right").foregroundStyle(Color.hwSecondary).accessibilityHidden(true)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("After").font(.subheadline).foregroundStyle(Color.hwSecondary)
                                Text(after.title).font(.title3.bold())
                            }
                        }
                    }
                }
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

/// Stand-in for the Apple Watch screen while the step happens.
struct WithYouView: View {
    let onEnd: () -> Void
    @State private var slowDown = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            OrbView(calm: !slowDown, size: 180)
            Text(slowDown ? "Slow down a little" : "You're doing well")
                .font(.title.bold())
                .padding(.top, 24)
            Text(slowDown ? "Rest on the landing. Take a breath." : "Your Watch taps your wrist to keep you company. Stop anytime.")
                .foregroundStyle(Color.hwSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            #if DEBUG
            Button(slowDown ? "Demo: back to calm" : "Demo: slow down") { slowDown.toggle() }
                .font(.subheadline)
            #endif
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
        .environment(AppModel(preview: true))
}
