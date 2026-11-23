//
//  QuestionPage.swift
//  Hearthware
//
//  One question with choices and a pill button. Used by onboarding and the step flow.
//

import SwiftUI

/// Shared layout for a single question with choices.
struct QuestionPage<Choices: View>: View {
    let step: String
    let title: String
    let subtitle: String
    let footnote: String?
    let buttonTitle: String
    let action: () -> Void
    var buttonDisabled = false
    @ViewBuilder var choices: Choices

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(step)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.hwSecondary)
                Text(title)
                    .font(.largeTitle.bold())
                    .padding(.top, 4)
                Text(subtitle)
                    .foregroundStyle(Color.hwSecondary)
                    .padding(.top, 8)
                VStack(spacing: 8) { choices }
                    .padding(.top, 28)
                if let footnote {
                    Text(footnote)
                        .font(.subheadline)
                        .foregroundStyle(Color.hwSecondary)
                        .padding(.top, 16)
                }
            }
            .padding(.horizontal, 20)
        }
        .safeAreaInset(edge: .bottom) {
            Button(buttonTitle, action: action)
                .buttonStyle(.pill)
                .disabled(buttonDisabled)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
    }
}
