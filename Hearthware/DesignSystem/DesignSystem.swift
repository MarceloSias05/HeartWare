//
//  DesignSystem.swift
//  Hearthware
//
//  Less is more. System fonts with Dynamic Type, system backgrounds,
//  contrast of 4.5:1 or more, and colour that never works alone.
//
//  Shape rule: actions, choices and one-line fields are capsules (a 28 pt radius, so
//  they stay a capsule at 56 pt and become a soft card when large text wraps); cards are
//  24 pt rounded rectangles; a multi-line text box is 16 pt. Spacing is on a
//  4 pt grid: 4, 8, 12, 16, 20, 24, 32. Screen margins are 20.
//

import SwiftUI

extension Color {
    /// Secondary text with enough contrast (≈5:1 on white). Adapts to dark mode.
    static let hwSecondary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(white: 0.70, alpha: 1) : UIColor(red: 0.424, green: 0.424, blue: 0.439, alpha: 1)
    })
    /// Soft container colour (the grey cards of the prototype).
    static let hwCard = Color(uiColor: .secondarySystemBackground)
    static let hwMint = Color(red: 0.0, green: 0.76, blue: 0.66)
    static let hwAmber = Color(red: 1.0, green: 0.70, blue: 0.25)
    /// Accessible red for help and emergencies only (≈5.4:1 on white).
    static let hwRed = Color(red: 0.84, green: 0.0, blue: 0.08)
    /// Red used as text on a card: lighter in dark mode so it keeps 4.5:1 on dark grey (fills keep `hwRed`).
    static let hwRedText = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(red: 1.0, green: 0.42, blue: 0.40, alpha: 1) : UIColor(red: 0.84, green: 0.0, blue: 0.08, alpha: 1)
    })
}

enum Space {
    static let screen: CGFloat = 20
    static let card: CGFloat = 20
}

enum Radius {
    /// Half of the 56 pt control height: a capsule that doesn't turn into a lozenge at large text.
    static let pill: CGFloat = 28
    static let card: CGFloat = 24
    static let textBox: CGFloat = 16
}

/// Black pill in light mode, white pill in dark mode. 56 pt tall, full width.
/// Gives way under the finger the moment it is pressed, and springs back.
struct PillButtonStyle: ButtonStyle {
    var role: Role = .primary
    enum Role { case primary, secondary, destructive }
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(foreground)
            .background(background, in: .rect(cornerRadius: Radius.pill))
            .opacity(isEnabled ? 1 : 0.35)
            .pressable(configuration.isPressed)
            .contentShape(.rect(cornerRadius: Radius.pill))
    }

    private var foreground: Color {
        switch role {
        case .primary: Color(uiColor: .systemBackground)
        case .secondary: .primary
        case .destructive: .white
        }
    }

    private var background: Color {
        switch role {
        case .primary: .primary
        case .secondary: .hwCard
        case .destructive: .hwRed
        }
    }
}

extension ButtonStyle where Self == PillButtonStyle {
    static var pill: PillButtonStyle { PillButtonStyle() }
    static var pillSecondary: PillButtonStyle { PillButtonStyle(role: .secondary) }
    static var pillDestructive: PillButtonStyle { PillButtonStyle(role: .destructive) }
}

/// A whole card that is one tap target: it sinks slightly while pressed.
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .pressable(configuration.isPressed, scale: 0.98)
            .contentShape(.rect(cornerRadius: Radius.card))
    }
}

extension ButtonStyle where Self == CardButtonStyle {
    static var card: CardButtonStyle { CardButtonStyle() }
}

extension View {
    /// Press feedback: a small scale on touch-down, a quick spring back on release.
    func pressable(_ pressed: Bool, scale: CGFloat = 0.97) -> some View {
        self
            .scaleEffect(pressed ? scale : 1)
            .opacity(pressed ? 0.85 : 1)
            .animation(.spring(duration: 0.2, bounce: 0), value: pressed)
    }
}

/// Grey rounded container used across the app.
struct Container<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Space.card)
            .background(Color.hwCard, in: .rect(cornerRadius: Radius.card))
    }
}

/// One selectable row used for goals and conditions.
struct ChoiceRow: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.body.weight(selected ? .semibold : .regular))
                Spacer()
                Image(systemName: "checkmark")
                    .fontWeight(.semibold)
                    .opacity(selected ? 1 : 0)
                    .scaleEffect(selected ? 1 : 0.6)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .frame(minHeight: 52)
            .foregroundStyle(selected ? Color(uiColor: .systemBackground) : .primary)
            .background(selected ? Color.primary : Color.hwCard, in: .rect(cornerRadius: Radius.pill))
            .contentShape(.rect(cornerRadius: Radius.pill))
            .animation(.spring(duration: 0.25, bounce: 0), value: selected)
        }
        .buttonStyle(.card)
        .sensoryFeedback(.selection, trigger: selected) { _, now in now }
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }
}

/// A one-line text field in the app's capsule shape.
struct CapsuleField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .frame(minHeight: 52)
            .background(Color.hwCard, in: .rect(cornerRadius: Radius.pill))
    }
}

extension View {
    func capsuleField() -> some View { modifier(CapsuleField()) }
}

/// "1 of 5" as five short bars, read aloud as words.
struct StepProgress: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...total, id: \.self) { i in
                Capsule()
                    .fill(i <= current ? Color.primary : Color.primary.opacity(0.15))
                    .frame(height: 4)
            }
        }
        .frame(maxWidth: 120)
        .accessibilityElement()
        .accessibilityLabel("Step \(current) of \(total)")
    }
}
