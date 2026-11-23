//
//  FeelingPage.swift
//  Hearthware
//
//  "How do you feel?" as a face you slide from very scared to calm. The whole
//  screen warms or cools with it. Words only, never a number on screen.
//

import SwiftUI

struct FeelingPage: View {
    let eyebrow: String
    let question: String
    var footnote: String? = nil
    let buttonTitle: String
    @Binding var feeling: Feeling
    let action: () -> Void

    /// 0 = very scared … 3 = calm. Continuous while dragging, snaps to a feeling on release.
    @State private var level: Double

    init(eyebrow: String, question: String, footnote: String? = nil, buttonTitle: String,
         feeling: Binding<Feeling>, action: @escaping () -> Void) {
        self.eyebrow = eyebrow
        self.question = question
        self.footnote = footnote
        self.buttonTitle = buttonTitle
        _feeling = feeling
        self.action = action
        _level = State(initialValue: Double(Feeling.veryScared.rawValue - feeling.wrappedValue.rawValue))
    }

    private var calmness: Double { level / 3 }
    private static let ink = Color(white: 0.13)

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
            FeelingFace(calmness: calmness)
                .frame(width: 220, height: 150)
                .accessibilityHidden(true)
            Spacer(minLength: 16)

            Text(feeling.title.uppercased())
                .font(.system(size: 52, weight: .black))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .contentTransition(.interpolate)
                .opacity(0.85)
                .accessibilityHidden(true)

            Slider(value: $level, in: 0...3) {
                Text(question)
            } minimumValueLabel: {
                Text("Very scared").font(.caption)
            } maximumValueLabel: {
                Text("Calm").font(.caption)
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

            if let footnote {
                Text(footnote)
                    .font(.subheadline)
                    .foregroundStyle(Self.ink.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
            }
            Spacer(minLength: 24)
            Button(buttonTitle, action: action)
                .buttonStyle(.pill)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
        .foregroundStyle(Self.ink)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Color.hwAmber.mix(with: .hwMint, by: calmness)
                .mix(with: .white, by: 0.35)
                .ignoresSafeArea()
        }
        // Always pastel with dark ink, in light and dark mode.
        .environment(\.colorScheme, .light)
        .onChange(of: level) {
            let snapped = Feeling(rawValue: Feeling.veryScared.rawValue - Int(level.rounded())) ?? feeling
            if snapped != feeling { feeling = snapped }
        }
        .sensoryFeedback(.selection, trigger: feeling)
        .animation(.easeOut(duration: 0.15), value: feeling)
    }
}

/// Two eyes and a mouth: wide-open eyes and a frown when scared, relaxed eyes and a smile when calm.
struct FeelingFace: View {
    /// 0 very scared … 1 calm.
    var calmness: Double

    var body: some View {
        let ink = Color(white: 0.13)
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
    NavigationStack {
        FeelingPage(eyebrow: "Climb one floor, slowly", question: "How do you feel about it?",
                    footnote: "There is no wrong answer. Feeling scared is normal.",
                    buttonTitle: "Start your step", feeling: $feeling) {}
    }
}
