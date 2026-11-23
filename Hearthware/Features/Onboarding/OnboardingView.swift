//
//  OnboardingView.swift
//  Hearthware
//
//  Three screens: welcome, what you want back, what happened to your heart.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @State private var path: [Page] = []
    @State private var goal: Goal = .stairs
    @State private var condition: HeartCondition = .heartAttack

    enum Page: Hashable { case goal, condition }

    var body: some View {
        NavigationStack(path: $path) {
            welcome
                .navigationDestination(for: Page.self) { page in
                    switch page {
                    case .goal: goalPage
                    case .condition: conditionPage
                    }
                }
        }
    }

    // MARK: Welcome

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 0) {
            Container {
                OrbView(size: 150)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
            }
            .padding(.top, 24)

            Text("Let's get back\nto your life")
                .font(.largeTitle.bold())
                .padding(.top, 32)
            Text("After a heart problem, everyday things can feel scary. We'll take them back together, one small step at a time.")
                .font(.body)
                .foregroundStyle(Color.hwSecondary)
                .padding(.top, 12)

            Spacer(minLength: 24)

            Button("Get started") { path.append(.goal) }
                .buttonStyle(.pill)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: Goal

    private var goalPage: some View {
        QuestionPage(
            step: "1 of 2",
            title: "What do you want\nto get back to?",
            subtitle: "Pick one. We'll start small.",
            footnote: nil,
            buttonTitle: "Continue",
            action: { path.append(.condition) }
        ) {
            ForEach(Goal.allCases) { option in
                ChoiceRow(title: option.title, selected: goal == option) { goal = option }
            }
        }
    }

    // MARK: Condition

    private var conditionPage: some View {
        QuestionPage(
            step: "2 of 2",
            title: "What happened\nto your heart?",
            subtitle: "This helps us explain what you feel.",
            footnote: "We never diagnose. Your doctor always has the last word.",
            buttonTitle: "Continue",
            action: finish
        ) {
            ForEach(HeartCondition.allCases) { option in
                ChoiceRow(title: option.title, selected: condition == option) { condition = option }
            }
        }
    }

    private func finish() {
        model.completeOnboarding(goal: goal, condition: condition)
    }
}

#Preview {
    OnboardingView()
        .environment(AppModel.preview(sample: false))
}
