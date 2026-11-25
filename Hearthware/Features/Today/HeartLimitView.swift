//
//  HeartLimitView.swift
//  Hearthware
//
//  The heart rate limit the doctor gave. The only number the person types; the Watch
//  turns it into "Slow down a little" and never shows it back. Opens as a sheet.
//

import SwiftUI

struct HeartLimitView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var limit: Int?
    @FocusState private var focused: Bool

    private var isValid: Bool { limit.map(HeartLimit.range.contains) ?? false }

    var body: some View {
        QuestionPage(
            step: "Your doctor's limit",
            title: "Did your doctor give you a heart rate limit?",
            subtitle: "If you pass it during a step, your Apple Watch taps your wrist and tells you to slow down.",
            footnote: "Only use the number your doctor gave you. Leave it empty if they didn't give one.",
            buttonTitle: "Save",
            action: {
                model.setHeartRateLimit(limit)
                dismiss()
            },
            buttonDisabled: limit != nil && !isValid
        ) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    field
                    unit
                }
                VStack(alignment: .leading, spacing: 4) {
                    field
                    unit
                }
            }
            .capsuleField()
            if model.heartRateLimit != nil {
                Button("Remove the limit") {
                    model.setHeartRateLimit(nil)
                    dismiss()
                }
                .buttonStyle(.pillSecondary)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", systemImage: "xmark") { dismiss() }
            }
        }
        .onAppear {
            limit = model.heartRateLimit
            focused = true
        }
    }

    private var field: some View {
        TextField("For example: 120", value: $limit, format: .number)
            .keyboardType(.numberPad)
            .focused($focused)
            .font(.title3.weight(.semibold))
            .monospacedDigit()
    }

    private var unit: some View {
        Text("beats per minute")
            .foregroundStyle(Color.hwSecondary)
    }
}

#Preview {
    NavigationStack { HeartLimitView() }
        .environment(AppModel(container: .empty))
}
