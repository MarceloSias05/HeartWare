//
//  DesignSystem.swift
//  Hearthware
//
//  Less is more. System fonts with Dynamic Type, system backgrounds,
//  contrast of 4.5:1 or more, and colour that never works alone.
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
}

/// Black pill in light mode, white pill in dark mode. 56 pt tall, full width.
struct PillButtonStyle: ButtonStyle {
    var role: Role = .primary
    enum Role { case primary, secondary, destructive }
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(foreground)
            .background(background, in: .capsule)
            .opacity(!isEnabled ? 0.35 : configuration.isPressed ? 0.75 : 1)
            .contentShape(.capsule)
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

/// Grey rounded container used across the app.
struct Container<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color.hwCard, in: .rect(cornerRadius: 28))
    }
}

/// One selectable row used for feelings, goals and conditions.
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
                if selected { Image(systemName: "checkmark").fontWeight(.semibold) }
            }
            .padding(.horizontal, 20)
            .frame(minHeight: 52)
            .foregroundStyle(selected ? Color(uiColor: .systemBackground) : .primary)
            .background(selected ? Color.primary : Color.hwCard, in: .capsule)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }
}
