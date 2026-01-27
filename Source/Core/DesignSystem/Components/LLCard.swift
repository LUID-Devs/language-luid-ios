//
//  LLCard.swift
//  LanguageLuid
//
//  Design System - Card Component
//  Reusable card with consistent styling and variants
//

import SwiftUI

/// Card style variants
enum LLCardStyle {
    case standard
    case elevated
    case outlined
    case filled

    func backgroundColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .standard, .elevated, .outlined:
            return LLColors.card.color(for: colorScheme)
        case .filled:
            return LLColors.muted.color(for: colorScheme)
        }
    }

    var borderWidth: CGFloat {
        switch self {
        case .outlined:
            return LLSpacing.borderStandard
        default:
            return 0
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .elevated:
            return LLSpacing.shadowMDRadius
        case .standard:
            return LLSpacing.shadowSMRadius
        default:
            return 0
        }
    }

    var shadowY: CGFloat {
        switch self {
        case .elevated:
            return LLSpacing.shadowMD
        case .standard:
            return LLSpacing.shadowSM
        default:
            return 0
        }
    }
}

/// Card padding variants
enum LLCardPadding {
    case none
    case sm
    case md
    case lg

    var edgeInsets: EdgeInsets {
        switch self {
        case .none:
            return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        case .sm:
            return EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        case .md:
            return LLSpacing.cardPadding
        case .lg:
            return EdgeInsets(top: 32, leading: 32, bottom: 32, trailing: 32)
        }
    }
}

/// Custom card component following the design system
struct LLCard<Content: View>: View {
    // MARK: - Properties

    let style: LLCardStyle
    let padding: LLCardPadding
    let cornerRadius: CGFloat
    let onTap: (() -> Void)?
    let content: Content

    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false

    // MARK: - Initializer

    init(
        style: LLCardStyle = .standard,
        padding: LLCardPadding = .md,
        cornerRadius: CGFloat = LLSpacing.radiusLG,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.onTap = onTap
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let onTap = onTap {
                Button(action: onTap) {
                    cardContent
                }
                .buttonStyle(CardPressButtonStyle(isPressed: $isPressed))
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
            } else {
                cardContent
            }
        }
    }

    // MARK: - Card Content

    private var cardContent: some View {
        content
            .padding(padding.edgeInsets)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(style.backgroundColor(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LLColors.border.color(for: colorScheme),
                        lineWidth: style.borderWidth
                    )
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
                radius: style.shadowRadius,
                x: 0,
                y: style.shadowY
            )
    }
}

// MARK: - Card Header

struct LLCardHeader<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LLSpacing.xs) {
            content
        }
        .padding(LLSpacing.cardHeaderPadding)
    }
}

// MARK: - Card Title

struct LLCardTitle: View {
    let title: String
    @Environment(\.colorScheme) var colorScheme

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(LLTypography.h4())
            .tracking(LLTypography.letterSpacingTight)
            .foregroundColor(LLColors.cardForeground.color(for: colorScheme))
            .lineLimit(2)
    }
}

// MARK: - Card Description

struct LLCardDescription: View {
    let description: String
    @Environment(\.colorScheme) var colorScheme

    init(_ description: String) {
        self.description = description
    }

    var body: some View {
        Text(description)
            .font(LLTypography.bodySmall())
            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            .lineLimit(3)
    }
}

// MARK: - Card Content

struct LLCardContent<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(LLSpacing.cardContentPadding)
    }
}

// MARK: - Card Footer

struct LLCardFooter<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack {
            content
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}

// MARK: - Card Image

struct LLCardImage: View {
    let image: Image
    let aspectRatio: CGFloat?
    let cornerRadius: CGFloat

    init(
        _ image: Image,
        aspectRatio: CGFloat? = nil,
        cornerRadius: CGFloat = LLSpacing.radiusLG
    ) {
        self.image = image
        self.aspectRatio = aspectRatio
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        image
            .resizable()
            .aspectRatio(aspectRatio, contentMode: .fill)
            .clipShape(
                RoundedRectangle(cornerRadius: cornerRadius)
            )
    }
}

// MARK: - Predefined Card Layouts
// NOTE: Static convenience methods removed due to generic parameter inference issues
// Use LLCard() initializer directly instead

// MARK: - Interactive Card

struct LLInteractiveCard<Content: View>: View {
    let content: Content
    let style: LLCardStyle
    let action: () -> Void

    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme

    init(
        style: LLCardStyle = .standard,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action) {
            content
                .padding(LLSpacing.cardPadding)
                .background(
                    RoundedRectangle(cornerRadius: LLSpacing.radiusLG)
                        .fill(style.backgroundColor(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LLSpacing.radiusLG)
                        .strokeBorder(
                            LLColors.border.color(for: colorScheme),
                            lineWidth: style.borderWidth
                        )
                )
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
                    radius: style.shadowRadius,
                    x: 0,
                    y: style.shadowY
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(CardPressButtonStyle(isPressed: $isPressed))
    }
}

// MARK: - Custom Button Style

struct CardPressButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Language Card (Specialized)

struct LLLanguageCard: View {
    let languageName: String
    let flagEmoji: String
    let lessonsCount: Int
    let progress: Double
    let onTap: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        LLInteractiveCard(style: .elevated, action: onTap) {
            VStack(alignment: .leading, spacing: LLSpacing.md) {
                HStack {
                    Text(flagEmoji)
                        .font(.system(size: 48))

                    Spacer()

                    if progress > 0 {
                        Text("\(Int(progress * 100))%")
                            .font(LLTypography.h4())
                            .foregroundColor(LLColors.primary.color(for: colorScheme))
                    }
                }

                VStack(alignment: .leading, spacing: LLSpacing.xs) {
                    Text(languageName)
                        .font(LLTypography.h4())
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))

                    Text("\(lessonsCount) lessons")
                        .font(LLTypography.bodySmall())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }

                // Progress Bar
                if progress > 0 {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: LLSpacing.radiusFull)
                                .fill(LLColors.muted.color(for: colorScheme))
                                .frame(height: LLSpacing.progressBarHeight)

                            RoundedRectangle(cornerRadius: LLSpacing.radiusFull)
                                .fill(LLColors.primary.color(for: colorScheme))
                                .frame(width: geometry.size.width * progress, height: LLSpacing.progressBarHeight)
                        }
                    }
                    .frame(height: LLSpacing.progressBarHeight)
                }
            }
        }
    }
}

// MARK: - Preview
// TODO: Fix preview - generic parameter inference issues with static methods
/*
#Preview("Cards") {
    ScrollView {
        VStack(spacing: LLSpacing.lg) {
            // Standard Card
            LLCard.standard(
                title: "Welcome to LanguageLuid",
                description: "Start learning a new language today"
            ) {
                Text("Card content goes here")
                    .font(LLTypography.body())
            }

            // Simple Card
            LLCard.simple {
                VStack(alignment: .leading, spacing: LLSpacing.sm) {
                    Text("Simple Card")
                        .font(LLTypography.h4())
                    Text("This is a simple card with minimal styling")
                        .font(LLTypography.bodySmall())
                }
            }

            // Elevated Card
            LLCard(style: .elevated) {
                Text("Elevated Card")
                    .font(LLTypography.h4())
            }

            // Outlined Card
            LLCard(style: .outlined) {
                Text("Outlined Card")
                    .font(LLTypography.h4())
            }

            // Interactive Card
            LLCard(style: .standard, onTap: {
                print("Card tapped")
            }) {
                Text("Tap me!")
                    .font(LLTypography.h4())
            }

            // Language Card
            LLLanguageCard(
                languageName: "Spanish",
                flagEmoji: "🇪🇸",
                lessonsCount: 24,
                progress: 0.65
            ) {
                print("Spanish tapped")
            }
        }
        .padding()
    }
}
*/
