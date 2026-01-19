//
//  LLBadge.swift
//  LanguageLuid
//
//  Design System - Badge Component
//  Reusable badge with color variants and sizes
//

import SwiftUI

/// Badge color variants
enum LLBadgeVariant {
    case `default`
    case secondary
    case success
    case warning
    case error
    case info
    case outline

    func backgroundColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .default:
            return LLColors.muted.color(for: colorScheme)
        case .secondary:
            return LLColors.secondary.color(for: colorScheme)
        case .success:
            return LLColors.success.color(for: colorScheme)
        case .warning:
            return LLColors.warning.color(for: colorScheme)
        case .error:
            return LLColors.destructive.color(for: colorScheme)
        case .info:
            return LLColors.info.color(for: colorScheme)
        case .outline:
            return Color.clear
        }
    }

    func foregroundColor(for colorScheme: ColorScheme) -> Color {
        switch self {
        case .default:
            return LLColors.foreground.color(for: colorScheme)
        case .secondary:
            return LLColors.secondaryForeground.color(for: colorScheme)
        case .success:
            return LLColors.successForeground.color(for: colorScheme)
        case .warning:
            return LLColors.warningForeground.color(for: colorScheme)
        case .error:
            return LLColors.destructiveForeground.color(for: colorScheme)
        case .info:
            return LLColors.infoForeground.color(for: colorScheme)
        case .outline:
            return LLColors.foreground.color(for: colorScheme)
        }
    }

    var borderColor: ColorSet? {
        switch self {
        case .outline:
            return LLColors.border
        default:
            return nil
        }
    }
}

/// Badge size variants
enum LLBadgeSize {
    case sm
    case md
    case lg

    var height: CGFloat {
        switch self {
        case .sm:
            return LLSpacing.badgeHeightSM
        case .md:
            return LLSpacing.badgeHeightMD
        case .lg:
            return LLSpacing.badgeHeightLG
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .sm:
            return LLSpacing.badgePaddingHorizontalSM
        case .md, .lg:
            return LLSpacing.badgePaddingHorizontal
        }
    }

    var font: Font {
        switch self {
        case .sm:
            return LLTypography.captionSmall()
        case .md:
            return LLTypography.caption()
        case .lg:
            return LLTypography.captionLarge()
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .sm:
            return 10
        case .md:
            return 12
        case .lg:
            return 14
        }
    }
}

/// Custom badge component following the design system
struct LLBadge: View {
    // MARK: - Properties

    let text: String?
    let icon: Image?
    let variant: LLBadgeVariant
    let size: LLBadgeSize
    let showDot: Bool

    @Environment(\.colorScheme) var colorScheme

    // MARK: - Initializers

    /// Create a text badge
    init(
        _ text: String,
        variant: LLBadgeVariant = .default,
        size: LLBadgeSize = .md
    ) {
        self.text = text
        self.icon = nil
        self.variant = variant
        self.size = size
        self.showDot = false
    }

    /// Create a badge with text and icon
    init(
        _ text: String,
        icon: Image,
        variant: LLBadgeVariant = .default,
        size: LLBadgeSize = .md
    ) {
        self.text = text
        self.icon = icon
        self.variant = variant
        self.size = size
        self.showDot = false
    }

    /// Create a dot indicator badge
    init(
        variant: LLBadgeVariant = .default,
        size: LLBadgeSize = .md
    ) {
        self.text = nil
        self.icon = nil
        self.variant = variant
        self.size = size
        self.showDot = true
    }

    // MARK: - Body

    var body: some View {
        if showDot {
            dotBadge
        } else {
            textBadge
        }
    }

    // MARK: - Text Badge

    private var textBadge: some View {
        HStack(spacing: LLSpacing.xs) {
            if let icon = icon {
                icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.iconSize, height: size.iconSize)
            }

            if let text = text {
                Text(text)
                    .font(size.font)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
        }
        .foregroundColor(variant.foregroundColor(for: colorScheme))
        .padding(.horizontal, size.horizontalPadding)
        .frame(height: size.height)
        .background(
            Capsule()
                .fill(variant.backgroundColor(for: colorScheme))
        )
        .overlay(
            Capsule()
                .strokeBorder(
                    variant.borderColor?.color(for: colorScheme) ?? Color.clear,
                    lineWidth: LLSpacing.borderStandard
                )
        )
    }

    // MARK: - Dot Badge

    private var dotBadge: some View {
        Circle()
            .fill(variant.backgroundColor(for: colorScheme))
            .frame(width: dotSize, height: dotSize)
            .overlay(
                Circle()
                    .strokeBorder(
                        variant.borderColor?.color(for: colorScheme) ?? Color.clear,
                        lineWidth: LLSpacing.borderThin
                    )
            )
    }

    private var dotSize: CGFloat {
        switch size {
        case .sm: return 8
        case .md: return 10
        case .lg: return 12
        }
    }
}

// MARK: - Specialized Badges

extension LLBadge {
    /// Create a CEFR level badge (A1, A2, B1, B2, C1, C2)
    static func cefrLevel(_ level: String) -> some View {
        LLBadge(level, variant: .info, size: .sm)
    }

    /// Create a status badge
    static func status(_ status: String, isActive: Bool) -> some View {
        LLBadge(
            status,
            variant: isActive ? .success : .default,
            size: .sm
        )
    }

    /// Create a count badge
    static func count(_ count: Int) -> some View {
        LLBadge(
            "\(count)",
            variant: .default,
            size: .sm
        )
    }
}

// MARK: - Badge Group

struct LLBadgeGroup: View {
    let badges: [AnyView]
    let spacing: CGFloat

    init(
        spacing: CGFloat = LLSpacing.xs,
        @ViewBuilder content: () -> [AnyView]
    ) {
        self.badges = content()
        self.spacing = spacing
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<badges.count, id: \.self) { index in
                badges[index]
            }
        }
    }
}

// MARK: - Notification Badge

struct LLNotificationBadge: View {
    let count: Int
    let size: LLBadgeSize
    @Environment(\.colorScheme) var colorScheme

    init(count: Int, size: LLBadgeSize = .sm) {
        self.count = count
        self.size = size
    }

    var body: some View {
        if count > 0 {
            Text(countText)
                .font(size.font)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, horizontalPadding)
                .frame(minWidth: minWidth, minHeight: minWidth)
                .background(
                    Capsule()
                        .fill(LLColors.destructive.color(for: colorScheme))
                )
        }
    }

    private var countText: String {
        count > 99 ? "99+" : "\(count)"
    }

    private var minWidth: CGFloat {
        switch size {
        case .sm: return 16
        case .md: return 20
        case .lg: return 24
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .sm: return 4
        case .md: return 6
        case .lg: return 8
        }
    }
}

// MARK: - Achievement Badge

struct LLAchievementBadge: View {
    let title: String
    let icon: Image
    let isUnlocked: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: LLSpacing.sm) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? LLColors.primary.color(for: colorScheme) : LLColors.muted.color(for: colorScheme))
                    .frame(width: 64, height: 64)

                icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .foregroundColor(isUnlocked ? .white : LLColors.mutedForeground.color(for: colorScheme))
            }

            Text(title)
                .font(LLTypography.captionSmall())
                .foregroundColor(isUnlocked ? LLColors.foreground.color(for: colorScheme) : LLColors.mutedForeground.color(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

// MARK: - Preview

#Preview("Badges") {
    ScrollView {
        VStack(alignment: .leading, spacing: LLSpacing.xl) {
            // Color Variants
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Color Variants")
                    .font(LLTypography.h4())

                HStack(spacing: LLSpacing.sm) {
                    LLBadge("Default", variant: .default)
                    LLBadge("Secondary", variant: .secondary)
                    LLBadge("Success", variant: .success)
                }

                HStack(spacing: LLSpacing.sm) {
                    LLBadge("Warning", variant: .warning)
                    LLBadge("Error", variant: .error)
                    LLBadge("Info", variant: .info)
                }

                HStack(spacing: LLSpacing.sm) {
                    LLBadge("Outline", variant: .outline)
                }
            }

            Divider()

            // Sizes
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Sizes")
                    .font(LLTypography.h4())

                HStack(spacing: LLSpacing.sm) {
                    LLBadge("Small", size: .sm)
                    LLBadge("Medium", size: .md)
                    LLBadge("Large", size: .lg)
                }
            }

            Divider()

            // With Icons
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("With Icons")
                    .font(LLTypography.h4())

                HStack(spacing: LLSpacing.sm) {
                    LLBadge("Beginner", icon: Image(systemName: "star.fill"), variant: .info)
                    LLBadge("Advanced", icon: Image(systemName: "flame.fill"), variant: .warning)
                    LLBadge("Expert", icon: Image(systemName: "crown.fill"), variant: .success)
                }
            }

            Divider()

            // Dot Indicators
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Dot Indicators")
                    .font(LLTypography.h4())

                HStack(spacing: LLSpacing.md) {
                    HStack(spacing: LLSpacing.xs) {
                        LLBadge(variant: .success, size: .sm)
                        Text("Online")
                            .font(LLTypography.bodySmall())
                    }

                    HStack(spacing: LLSpacing.xs) {
                        LLBadge(variant: .error, size: .sm)
                        Text("Offline")
                            .font(LLTypography.bodySmall())
                    }

                    HStack(spacing: LLSpacing.xs) {
                        LLBadge(variant: .warning, size: .sm)
                        Text("Away")
                            .font(LLTypography.bodySmall())
                    }
                }
            }

            Divider()

            // Notification Badges
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Notification Badges")
                    .font(LLTypography.h4())

                HStack(spacing: LLSpacing.lg) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 32))
                        LLNotificationBadge(count: 5)
                            .offset(x: 8, y: -8)
                    }

                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 32))
                        LLNotificationBadge(count: 99)
                            .offset(x: 8, y: -8)
                    }

                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 32))
                        LLNotificationBadge(count: 150)
                            .offset(x: 8, y: -8)
                    }
                }
            }

            Divider()

            // CEFR Levels
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("CEFR Levels")
                    .font(LLTypography.h4())

                HStack(spacing: LLSpacing.xs) {
                    LLBadge.cefrLevel("A1")
                    LLBadge.cefrLevel("A2")
                    LLBadge.cefrLevel("B1")
                    LLBadge.cefrLevel("B2")
                    LLBadge.cefrLevel("C1")
                    LLBadge.cefrLevel("C2")
                }
            }

            Divider()

            // Achievement Badges
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Achievement Badges")
                    .font(LLTypography.h4())

                HStack(spacing: LLSpacing.lg) {
                    LLAchievementBadge(
                        title: "First Lesson",
                        icon: Image(systemName: "star.fill"),
                        isUnlocked: true
                    )

                    LLAchievementBadge(
                        title: "7 Day Streak",
                        icon: Image(systemName: "flame.fill"),
                        isUnlocked: false
                    )

                    LLAchievementBadge(
                        title: "Master",
                        icon: Image(systemName: "crown.fill"),
                        isUnlocked: false
                    )
                }
            }
        }
        .padding()
    }
}
