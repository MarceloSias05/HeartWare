//
//  FeelingPage.swift
//  Hearthware
//
//  "How do you feel?" as a face you slide from very scared to calm. The whole
//  screen takes the feeling's colour. Words only, never a number on screen.
//  The person can add a note to their answer if they want.
//

import SwiftUI

struct FeelingPage: View {
    /// Onboarding page out of 5, shown as bars instead of the eyebrow.
    var progress: Int? = nil
    let eyebrow: String?
    let question: String
    var footnote: String? = nil
    let buttonTitle: String
    @Binding var feeling: Feeling
    /// Nil hides "Add note".
    var note: Binding<String>?
    let action: () -> Void

    /// 0 = very scared … 3 = calm. Continuous while dragging, snaps to a feeling on release.
    @State private var level: Double
    @State private var writingNote = false
    @Environment(\.dynamicTypeSize) private var typeSize

    init(progress: Int? = nil, eyebrow: String?, question: String, footnote: String? = nil, buttonTitle: String,
         feeling: Binding<Feeling>, note: Binding<String>? = nil, action: @escaping () -> Void) {
        self.progress = progress
        self.eyebrow = eyebrow
        self.question = question
        self.footnote = footnote
        self.buttonTitle = buttonTitle
        _feeling = feeling
        self.note = note
        self.action = action
        _level = State(initialValue: Double(Feeling.veryScared.rawValue - feeling.wrappedValue.rawValue))
    }

    private var background: Color { FeelingPalette.color(at: level) }
    /// Same hue, darker: the big word and the soft buttons sit tone-on-tone on the background.
    private var shade: Color { background.mix(with: .black, by: 0.45) }
    private static let ink = Color(white: 0.12)

    var body: some View {
        // Fills the screen when it fits; scrolls at large text sizes instead of truncating.
        ViewThatFits(in: .vertical) {
            content
            ScrollView { content }
        }
        .safeAreaInset(edge: .bottom) { buttons }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
        .foregroundStyle(Self.ink)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { background.ignoresSafeArea() }
        // Always bright with dark ink, in light and dark mode.
        .environment(\.colorScheme, .light)
        .onChange(of: level) {
            let snapped = Feeling(rawValue: Feeling.veryScared.rawValue - Int(level.rounded())) ?? feeling
            if snapped != feeling { feeling = snapped }
        }
        .sensoryFeedback(.selection, trigger: feeling)
        .animation(.easeOut(duration: 0.15), value: feeling)
        .sheet(isPresented: $writingNote) {
            if let note { NoteSheet(question: question, note: note) }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                if let progress {
                    StepProgress(current: progress, total: 5)
                } else if let eyebrow {
                    Text(eyebrow)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Self.ink.opacity(0.7))
                }
                Text(question)
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
            }
            .multilineTextAlignment(.center)
            .padding(.top, 8)

            Spacer(minLength: 16)
            FeelingFace(calmness: level / 3)
                .frame(width: 220, height: 150)
                .accessibilityHidden(true)
            Spacer(minLength: 16)

            Text(feeling.title.uppercased())
                .font(.system(size: 54, weight: .black))
                .foregroundStyle(shade)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .contentTransition(.interpolate)
                .accessibilityHidden(true)

            Slider(value: $level, in: 0...3) {
                Text(question)
            } onEditingChanged: { editing in
                if !editing { withAnimation(.spring(duration: 0.35)) { level = level.rounded() } }
            }
            .tint(Self.ink)
            .accessibilityValue(feeling.title)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: level = min(3, level.rounded() + 1)
                case .decrement: level = max(0, level.rounded() - 1)
                @unknown default: break
                }
            }
            .padding(.top, 20)
            // Ends of the slider under it, so they never truncate at large text.
            HStack {
                Text("Very scared")
                Spacer(minLength: 16)
                Text("Calm")
            }
            .font(.caption.weight(.medium))
            .accessibilityHidden(true)

            Group {
                if let text = note?.wrappedValue, !text.isEmpty {
                    Text("“\(text)”").italic().lineLimit(2)
                } else if let footnote {
                    Text(footnote)
                }
            }
            .font(.subheadline)
            .foregroundStyle(Self.ink.opacity(0.65))
            .multilineTextAlignment(.center)
            .padding(.top, 16)

            Spacer(minLength: 24)
        }
    }

    /// Side by side; stacked at accessibility sizes so the main button keeps its width.
    private var buttons: some View {
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
        return layout {
            if let note {
                Button { writingNote = true } label: {
                    Label(note.wrappedValue.isEmpty ? "Add note" : "Edit note", systemImage: "square.and.pencil")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .frame(minHeight: 56)
                        .frame(maxWidth: typeSize.isAccessibilitySize ? .infinity : nil)
                        .background(shade.opacity(0.22), in: .rect(cornerRadius: Radius.pill))
                }
                .buttonStyle(.card)
                .fixedSize(horizontal: !typeSize.isAccessibilitySize, vertical: false)
            }
            Button(buttonTitle, action: action)
                .buttonStyle(.pill)
        }
        .padding(.top, 8)
        .background(background)
    }
}

/// A short, optional note for the answer. Goes in the summary for the doctor.
private struct NoteSheet: View {
    let question: String
    @Binding var note: String
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Anything you want to remember? Your doctor will see it in your summary.")
                    .foregroundStyle(Color.hwSecondary)
                TextField("For example: my knees were shaking", text: $note, axis: .vertical)
                    .lineLimit(3...6)
                    .focused($focused)
                    .padding(16)
                    .background(Color.hwCard, in: .rect(cornerRadius: Radius.textBox))
                Spacer()
            }
            .padding(20)
            .navigationTitle(question)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") { dismiss() }
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    @Previewable @State var feeling: Feeling = .nervous
    @Previewable @State var note = ""
    NavigationStack {
        FeelingPage(eyebrow: "Climb one floor, slowly", question: "How do you feel about it?",
                    footnote: "There is no wrong answer. Feeling scared is normal.",
                    buttonTitle: "Start your step", feeling: $feeling, note: $note) {}
    }
}
