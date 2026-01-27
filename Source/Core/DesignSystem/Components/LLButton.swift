//
//  LLButton.swift
//  LanguageLuid
//
//  Design System - Button Component
//  Reusable button with multiple styles and sizes
//

import SwiftUI

/// Button style variants matching the web app design
enum LLButtonStyle {
    case primary
    case secondary
    case outline
    case ghost
    case destructive
    case success
    case warning
    case link

    var backgroundColor: ColorSet {
        switch self {
        case .primary:
            return LLColors.primary
        case .secondary:
            return LLColors.secondary
        case .outline, .ghost, .link:
            return ColorSet(light: .clear, dark: .clear)
        case .destructive:
            return LLColors.destructive
        case .success:
            return LLColors.success
        case .warning:
            return LLColors.warning
        }
    }

    var foregroundColor: ColorSet {
        switch self {
        case .primary:
            return LLColors.primaryForeground
        case .secondary:
            return LLColors.secondaryForeground
        case .outline:
            return LLColors.foreground
        case .ghost:
            return LLColors.foreground
        case .destructive:
            return LLColors.destructiveForeground
        case .success:
            return LLColors.successForeground
        case .warning:
            return LLColors.warningForeground
        case .link:
            return LLColors.primary
        }
    }

    var borderColor: ColorSet? {
        switch self {
        case .outline:
            return LLColors.input
        default:
            return nil
        }
    }

    var hoverOpacity: Double {
        switch self {
        case .primary, .secondary, .destructive, .success, .warning:
            return 0.9
        case .outline, .ghost:
            return 1.0
        case .link:
            return 1.0
        }
    }
}

/// Button size variants
enum LLButtonSize {
    case sm
    case md
    case lg
    case icon

    var height: CGFloat {
        switch self {
        case .sm:
            return LLSpacing.buttonHeightSM
        case .md:
            return LLSpacing.buttonHeightMD
        case .lg:
            return LLSpacing.buttonHeightLG
        case .icon:
            return LLSpacing.buttonIconSize
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .sm:
            return 12
        case .md:
            return 16
        case .lg:
            return 32
        case .icon:
            return 0
        }
    }

    var font: Font {
        switch self {
        case .sm:
            return LLTypography.buttonSmall()
        case .md:
            return LLTypography.button()
        case .lg:
            return LLTypography.buttonLarge()
        case .icon:
            return LLTypography.button()
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .sm, .md:
            return LLSpacing.radiusMD
        case .lg:
            return LLSpacing.radiusLG
        case .icon:
            return LLSpacing.radiusMD
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .sm:
            return LLSpacing.iconSM
        case .md:
            return LLSpacing.iconMD
        case .lg:
            return LLSpacing.iconLG
        case .icon:
            return LLSpacing.iconMD
        }
    }
}

/// Custom button component following the design system
struct LLButton: View {
    // MARK: - Properties

    let title: String?
    let icon: Image?
    let style: LLButtonStyle
    let size: LLButtonSize
    let isLoading: Bool
    let isDisabled: Bool
    let fullWidth: Bool
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false

    // MARK: - Initializers

    /// Create a button with text
    init(
        _ title: String,
        style: LLButtonStyle = .primary,
        size: LLButtonSize = .md,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        fullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = nil
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.fullWidth = fullWidth
        self.action = action
    }

    /// Create a button with text and icon
    init(
        _ title: String,
        icon: Image,
        style: LLButtonStyle = .primary,
        size: LLButtonSize = .md,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        fullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.fullWidth = fullWidth
        self.action = action
    }

    /// Create an icon-only button
    init(
        icon: Image,
        style: LLButtonStyle = .primary,
        size: LLButtonSize = .icon,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = nil
        self.icon = icon
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.fullWidth = false
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: {
            guard !isDisabled && !isLoading else { return }
            action()
        }) {
            buttonContent
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1.0)
        .buttonStyle(PressEffectButtonStyle(isPressed: $isPressed))
        .accessibilityLabel(title ?? "Button")
        .accessibilityHint(isLoading ? "Loading" : "")
        .accessibilityAddTraits(.isButton)
    }

    private var buttonContent: some View {
        HStack(spacing: LLSpacing.sm) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(
                        tint: style.foregroundColor.color(for: colorScheme)
                    ))
                    .frame(width: size.iconSize, height: size.iconSize)
            } else if let icon = icon {
                icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.iconSize, height: size.iconSize)
            }

            if let title = title {
                Text(title)
                    .font(size.font)
                    .tracking(LLTypography.letterSpacingWide)
                    .lineLimit(1)
            }
        }
        .foregroundColor(style.foregroundColor.color(for: colorScheme))
        .frame(height: size.height)
        .frame(maxWidth: fullWidth ? .infinity : nil)
        .padding(.horizontal, size == .icon ? 0 : size.horizontalPadding)
        .background(buttonBackground)
        .overlay(buttonBorder)
        .overlay(buttonHoverOverlay)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }

    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: size.cornerRadius)
            .fill(style.backgroundColor.color(for: colorScheme))
            .opacity(buttonOpacity)
    }

    private var buttonBorder: some View {
        RoundedRectangle(cornerRadius: size.cornerRadius)
            .strokeBorder(
                style.borderColor?.color(for: colorScheme) ?? Color.clear,
                lineWidth: LLSpacing.borderStandard
            )
    }

    private var buttonHoverOverlay: some View {
        RoundedRectangle(cornerRadius: size.cornerRadius)
            .fill(hoverColor)
            .opacity(hoverOpacity)
    }

    // MARK: - Computed Properties

    private var buttonOpacity: Double {
        if isDisabled {
            return 0.5
        }
        return 1.0
    }

    private var hoverColor: Color {
        switch style {
        case .outline, .ghost:
            return LLColors.accent.color(for: colorScheme)
        case .link:
            return Color.clear
        default:
            return Color.black
        }
    }

    private var hoverOpacity: Double {
        if isPressed {
            switch style {
            case .outline, .ghost:
                return 0.1
            case .link:
                return 0
            default:
                return 0.1
            }
        }
        return 0
    }
}

// MARK: - Link Button Extension

extension LLButton {
    /// Create a link-style button with underline on hover
    static func link(
        _ title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(LLTypography.body())
                .foregroundColor(LLColors.primary.adaptive)
                .underline()
        }
    }
}

// MARK: - Button Group

/// Group of buttons with consistent spacing
struct LLButtonGroup: View {
    let buttons: [AnyView]
    let spacing: CGFloat
    let axis: Axis

    enum Axis {
        case horizontal
        case vertical
    }

    init(
        spacing: CGFloat = LLSpacing.sm,
        axis: Axis = .horizontal,
        @ViewBuilder content: () -> [AnyView]
    ) {
        self.buttons = content()
        self.spacing = spacing
        self.axis = axis
    }

    var body: some View {
        if axis == .horizontal {
            HStack(spacing: spacing) {
                ForEach(0..<buttons.count, id: \.self) { index in
                    buttons[index]
                }
            }
        } else {
            VStack(spacing: spacing) {
                ForEach(0..<buttons.count, id: \.self) { index in
                    buttons[index]
                }
            }
        }
    }
}

// MARK: - Custom Button Style

struct PressEffectButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Preview

#Preview("Button Styles") {
    VStack(spacing: LLSpacing.lg) {
        // Primary
        LLButton("Primary Button", style: .primary) {
            print("Primary tapped")
        }

        // Secondary
        LLButton("Secondary Button", style: .secondary) {
            print("Secondary tapped")
        }

        // Outline
        LLButton("Outline Button", style: .outline) {
            print("Outline tapped")
        }

        // Ghost
        LLButton("Ghost Button", style: .ghost) {
            print("Ghost tapped")
        }

        // Destructive
        LLButton("Destructive Button", style: .destructive) {
            print("Destructive tapped")
        }

        // With Icon
        LLButton("With Icon", icon: Image(systemName: "star.fill")) {
            print("Icon button tapped")
        }

        // Loading
        LLButton("Loading...", isLoading: true) {
            print("Loading tapped")
        }

        // Disabled
        LLButton("Disabled", isDisabled: true) {
            print("Disabled tapped")
        }

        // Icon Only
        LLButton(icon: Image(systemName: "gear"), size: .icon) {
            print("Icon only tapped")
        }

        // Sizes
        HStack(spacing: LLSpacing.sm) {
            LLButton("Small", size: .sm) { }
            LLButton("Medium", size: .md) { }
            LLButton("Large", size: .lg) { }
        }
    }
    .padding()
}
