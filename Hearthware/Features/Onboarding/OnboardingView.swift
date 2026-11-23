//
//  OnboardingView.swift
//  Hearthware
//
//  Welcome, then three questions: your name, what you want back, what happened to your heart.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @State private var path: [Page] = []
    @State private var input = OnboardingInput()
    @FocusState private var focused: Field?

    enum Page: Hashable { case name, goal, condition }
    enum Field { case name, customGoal }

    var body: some View {
        NavigationStack(path: $path) {
            welcome
                .navigationDestination(for: Page.self) { page in
                    switch page {
                    case .name: namePage
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

            Button("Get started") { path.append(.name) }
                .buttonStyle(.pill)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: Name

    private var namePage: some View {
        QuestionPage(
            step: "1 of 3",
            title: "What should\nwe call you?",
            subtitle: "We'll use it to greet you and on the summary for your doctor.",
            footnote: "Your name stays on this phone.",
            buttonTitle: "Continue",
            action: { path.append(.goal) },
            buttonDisabled: !input.nameIsValid
        ) {
            TextField("Your name", text: $input.name)
                .textContentType(.givenName)
                .textInputAutocapitalization(.words)
                .submitLabel(.continue)
                .focused($focused, equals: .name)
                .onSubmit { if input.nameIsValid { path.append(.goal) } }
                .padding(.horizontal, 20)
                .frame(minHeight: 52)
                .background(Color.hwCard, in: .capsule)
                .onAppear { focused = .name }
        }
    }

    // MARK: Goal

    private var goalPage: some View {
        QuestionPage(
            step: "2 of 3",
            title: "What do you want\nto get back to?",
            subtitle: "Pick one. We'll start small.",
            footnote: nil,
            buttonTitle: "Continue",
            action: { path.append(.condition) },
            buttonDisabled: !input.goalIsValid
        ) {
            ForEach(Goal.allCases) { option in
                ChoiceRow(title: option.title, selected: input.goal == option) {
                    input.goal = option
                    if option == .other { focused = .customGoal }
                }
            }
            if input.goal == .other {
                TextField("What do you want to get back to?", text: $input.customGoal)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                    .focused($focused, equals: .customGoal)
                    .padding(.horizontal, 20)
                    .frame(minHeight: 52)
                    .background(Color.hwCard, in: .capsule)
            }
        }
    }

    // MARK: Condition

    private var conditionPage: some View {
        QuestionPage(
            step: "3 of 3",
            title: "What happened\nto your heart?",
            subtitle: "This helps us explain what you feel.",
            footnote: "We never diagnose. Your doctor always has the last word.",
            buttonTitle: "Continue",
            action: finish
        ) {
            ForEach(HeartCondition.allCases) { option in
                ChoiceRow(title: option.title, selected: input.condition == option) { input.condition = option }
            }
        }
    }

    private func finish() {
        // Guard again: the button is disabled, but never save an incomplete profile.
        guard input.nameIsValid, input.goalIsValid else { return }
        model.completeOnboarding(name: input.trimmedName, goal: input.goal,
                                 customGoal: input.trimmedCustomGoal, condition: input.condition)
    }
}

#Preview {
    OnboardingView()
        .environment(AppModel(container: .empty))
}
