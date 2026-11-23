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
    let eyebrow: String
    let question: String
    var footnote: String? = nil
    let buttonTitle: String
    @Binding var feeling: Feeling
    @Binding var note: String
    let action: () -> Void

    /// 0 = very scared … 3 = calm. Continuous while dragging, snaps to a feeling on release.
    @State private var level: Double
    @State private var writingNote = false

    init(eyebrow: String, question: String, footnote: String? = nil, buttonTitle: String,
         feeling: Binding<Feeling>, note: Binding<String>, action: @escaping () -> Void) {
        self.eyebrow = eyebrow
        self.question = question
        self.footnote = footnote
        self.buttonTitle = buttonTitle
        _feeling = feeling
        _note = note
        self.action = action
        _level = State(initialValue: Double(Feeling.veryScared.rawValue - feeling.wrappedValue.rawValue))
    }

    private var background: Color { FeelingPalette.color(at: level) }
    /// Same hue, darker: the big word and the soft buttons sit tone-on-tone on the background.
    private var shade: Color { background.mix(with: .black, by: 0.32) }
    private static let ink = Color(white: 0.12)

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text(eyebrow)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Self.ink.opacity(0.6))
                Text(question)
                    .font(.title2.bold())
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
            } minimumValueLabel: {
                Text("Very scared").font(.caption.weight(.medium))
            } maximumValueLabel: {
                Text("Calm").font(.caption.weight(.medium))
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

            Group {
                if !note.isEmpty {
                    Text("“\(note)”").italic().lineLimit(2)
                } else if let footnote {
                    Text(footnote)
                }
            }
            .font(.subheadline)
            .foregroundStyle(Self.ink.opacity(0.65))
            .multilineTextAlignment(.center)
            .padding(.top, 16)

            Spacer(minLength: 24)
            HStack(spacing: 10) {
                Button { writingNote = true } label: {
                    Label(note.isEmpty ? "Add note" : "Edit note", systemImage: "square.and.pencil")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .frame(height: 56)
                        .background(shade.opacity(0.22), in: .capsule)
                }
                .buttonStyle(.plain)
                .fixedSize()
                Button(buttonTitle, action: action)
                    .buttonStyle(.pill)
            }
        }
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
            NoteSheet(question: question, note: $note)
        }
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
                    .padding(14)
                    .background(Color.hwCard, in: .rect(cornerRadius: 14))
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

/// One clear colour per feeling, blended between neighbours while dragging.
/// Very scared → orange, nervous → sunflower, a little nervous → green, calm → mint.
enum FeelingPalette {
    static let stops: [Color] = [
        Color(red: 1.00, green: 0.60, blue: 0.33),
        Color(red: 1.00, green: 0.79, blue: 0.29),
        Color(red: 0.60, green: 0.86, blue: 0.40),
        Color(red: 0.33, green: 0.86, blue: 0.73),
    ]

    /// `level` 0 (very scared) … 3 (calm).
    static func color(at level: Double) -> Color {
        let l = min(max(level, 0), 3)
        let i = min(Int(l), 2)
        return stops[i].mix(with: stops[i + 1], by: l - Double(i))
    }
}

/// Two eyes and a mouth: wide-open eyes and a frown when scared, relaxed eyes and a smile when calm.
struct FeelingFace: View {
    /// 0 very scared … 1 calm.
    var calmness: Double

    var body: some View {
        let ink = Color(white: 0.12)
        VStack(spacing: 26) {
            HStack(spacing: 22) {
                ForEach(0..<2, id: \.self) { _ in
                    Capsule().fill(ink)
                        .frame(width: 80, height: 56 - 30 * calmness)
                }
            }
            .frame(height: 56)
            Mouth(curve: calmness * 2 - 1)
                .stroke(ink, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 70 + 30 * calmness, height: 34)
        }
    }
}

/// curve 1 = smile, -1 = frown, 0 = flat.
struct Mouth: Shape {
    var curve: Double

    var animatableData: Double {
        get { curve }
        set { curve = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let lift = curve * rect.height / 2
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY - lift))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY - lift),
                          control: CGPoint(x: rect.midX, y: rect.midY + lift * 1.6))
        return path
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
