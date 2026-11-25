//
//  OnboardingView.swift
//  Hearthware
//
//  Welcome, then five pages: your name, what you want back, how you feel about it today,
//  what happened to your heart, and connecting Apple Health.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @State private var path: [Page] = []
    @State private var input = OnboardingInput()
    @FocusState private var focused: Field?

    enum Page: Hashable { case name, goal, feeling, condition, health }
    enum Field { case name, customGoal, customCondition }

    var body: some View {
        NavigationStack(path: $path) {
            welcome
                .navigationDestination(for: Page.self) { page in
                    switch page {
                    case .name: namePage
                    case .goal: goalPage
                    case .feeling: feelingPage
                    case .condition: conditionPage
                    case .health: healthPage
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
            step: "1 of 5",
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
            step: "2 of 5",
            title: "What do you want\nto get back to?",
            subtitle: "Pick one. We'll start small.",
            footnote: nil,
            buttonTitle: "Continue",
            action: { path.append(.feeling) },
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

    // MARK: Feeling today

    private var feelingPage: some View {
        FeelingPage(
            eyebrow: "3 of 5",
            question: "How do you feel about \(goalPhrase) today?",
            footnote: "There is no wrong answer. We'll see this change together.",
            buttonTitle: "Continue",
            feeling: $input.baselineFear,
            action: { path.append(.condition) }
        )
    }

    /// "climbing my stairs" from "Climbing my stairs", or the person's own words.
    private var goalPhrase: String {
        let title = input.trimmedCustomGoal ?? input.goal.title
        return title.prefix(1).lowercased() + title.dropFirst()
    }

    // MARK: Condition

    private var conditionPage: some View {
        QuestionPage(
            step: "4 of 5",
            title: "What happened\nto your heart?",
            subtitle: "This helps us explain what you feel.",
            footnote: "We never diagnose. Your doctor always has the last word.",
            buttonTitle: "Continue",
            action: { path.append(.health) },
            buttonDisabled: !input.conditionIsValid
        ) {
            ForEach(HeartCondition.allCases) { option in
                ChoiceRow(title: option.title, selected: input.condition == option) {
                    input.condition = option
                    if option == .other { focused = .customCondition }
                }
            }
            if input.condition == .other {
                TextField("What happened to your heart?", text: $input.customCondition)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                    .focused($focused, equals: .customCondition)
                    .padding(.horizontal, 20)
                    .frame(minHeight: 52)
                    .background(Color.hwCard, in: .capsule)
            }
        }
    }

    // MARK: Apple Health

    private var healthPage: some View {
        // Scrolls on small phones and large text sizes; buttons stay pinned at the bottom.
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("5 of 5")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.hwSecondary)
                Container {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.hwRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .accessibilityHidden(true)
                }
                .padding(.top, 12)
                Text("Show your doctor how far you've come")
                    .font(.largeTitle.bold())
                    .padding(.top, 28)
                Text("Steady reads your heart and walking history from Apple Health, including the weeks before today, so your doctor can see the before and after. You'll never see numbers here.")
                    .foregroundStyle(Color.hwSecondary)
                    .padding(.top, 10)
                Text("If you measure your blood pressure at home, add it in the Health app too: your doctor will see it.")
                    .foregroundStyle(Color.hwSecondary)
                    .padding(.top, 10)
                Text("Read only. It stays on your phone until you share the summary.")
                    .font(.subheadline)
                    .foregroundStyle(Color.hwSecondary)
                    .padding(.top, 12)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 20)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button("Connect Apple Health") {
                    Task {
                        await HealthHistory.requestAccess()
                        finish()
                    }
                }
                .buttonStyle(.pill)
                Button("Not now") { finish() }
                    .buttonStyle(.pillSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .background(Color(uiColor: .systemBackground))
        }
    }

    private func finish() {
        // Guard again: the buttons are disabled, but never save an incomplete profile.
        guard input.nameIsValid, input.goalIsValid, let condition = input.condition else { return }
        model.completeOnboarding(name: input.trimmedName, goal: input.goal, customGoal: input.trimmedCustomGoal,
                                 condition: condition, customCondition: input.trimmedCustomCondition,
                                 baselineFear: input.baselineFear)
    }
}

#Preview {
    OnboardingView()
        .environment(AppModel(container: .empty))
}
