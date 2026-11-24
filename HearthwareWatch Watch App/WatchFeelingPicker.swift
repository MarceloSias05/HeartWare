//
//  WatchFeelingPicker.swift
//  HearthwareWatch Watch App
//
//  "How do you feel?" on the wrist: turn the Digital Crown from very scared to calm.
//  The face and the colour follow, with a haptic tick on each feeling. A note can be
//  dictated or scribbled from the top-right button. Words only, never numbers.
//

import SwiftUI

struct WatchFeelingPicker: View {
    let question: String
    let buttonTitle: String
    @Binding var feeling: Feeling
    @Binding var note: String
    let action: () -> Void

    /// 0 = very scared … 3 = calm, one Crown detent per feeling.
    @State private var level: Double

    init(question: String, buttonTitle: String, feeling: Binding<Feeling>, note: Binding<String>,
         action: @escaping () -> Void) {
        self.question = question
        self.buttonTitle = buttonTitle
        _feeling = feeling
        _note = note
        self.action = action
        _level = State(initialValue: Double(Feeling.veryScared.rawValue - feeling.wrappedValue.rawValue))
    }

    private static let ink = Color(white: 0.1)

    var body: some View {
        VStack(spacing: 4) {
            VStack(spacing: 4) {
                Text(question)
                    .font(.footnote.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                FeelingFace(calmness: level / 3)
                    .scaleEffect(0.48)
                    .frame(width: 106, height: 72)
                Text(feeling.title)
                    .font(.system(size: 22, weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.interpolate)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(question)
            .accessibilityValue(feeling.title)
            .accessibilityHint("Turn the Digital Crown to change it.")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: level = min(3, level + 1)
                case .decrement: level = max(0, level - 1)
                @unknown default: break
                }
            }

            Button(buttonTitle, action: action)
                .buttonStyle(.borderedProminent)
                .tint(Self.ink)
                .foregroundStyle(.white)
        }
        .foregroundStyle(Self.ink)
        .focusable()
        .digitalCrownRotation($level, from: 0, through: 3, by: 1, sensitivity: .low,
                              isContinuous: false, isHapticFeedbackEnabled: true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Full-strength colour (containerBackground would dim it), with dark ink like on the iPhone.
        .background(FeelingPalette.color(at: level).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                TextFieldLink(prompt: Text("Add a note")) {
                    Image(systemName: note.isEmpty ? "square.and.pencil" : "text.bubble.fill")
                        .accessibilityLabel(note.isEmpty ? "Add a note" : "Edit note")
                } onSubmit: { note = $0 }
            }
        }
        .onChange(of: level) {
            let snapped = Feeling(rawValue: Feeling.veryScared.rawValue - Int(level.rounded())) ?? feeling
            if snapped != feeling { feeling = snapped }
        }
        .animation(.easeOut(duration: 0.15), value: feeling)
    }
}
