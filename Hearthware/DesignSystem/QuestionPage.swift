//
//  QuestionPage.swift
//  Hearthware
//
//  One question with choices and a pill button. Used by onboarding and the doctor's limit.
//

import SwiftUI

/// Shared layout for a single question with choices.
struct QuestionPage<Choices: View>: View {
    /// Onboarding page number out of 5, shown as bars.
    var progress: Int? = nil
    /// A short eyebrow above the title, when there is no progress.
    var step: String? = nil
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
                if let progress {
                    StepProgress(current: progress, total: 5)
                        .padding(.bottom, 16)
                } else if let step {
                    Text(step)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.hwSecondary)
                        .padding(.bottom, 4)
                }
                Text(title)
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Text(subtitle)
                    .foregroundStyle(Color.hwSecondary)
                    .padding(.top, 8)
                VStack(spacing: 8) { choices }
                    .padding(.top, 24)
                if let footnote {
                    Text(footnote)
                        .font(.subheadline)
                        .foregroundStyle(Color.hwSecondary)
                        .padding(.top, 16)
                }
            }
            .padding(.horizontal, Space.screen)
            .padding(.bottom, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            Button(buttonTitle, action: action)
                .buttonStyle(.pill)
                .disabled(buttonDisabled)
                .padding(.horizontal, Space.screen)
                .padding(.bottom, 8)
                .background(Color(uiColor: .systemBackground))
        }
    }
}
