//
//  LLEmptyState.swift
//  LanguageLuid
//
//  Design System - Empty State Component
//  Reusable empty state with icon, title, description, and optional action
//

import SwiftUI

/// Empty state style variants
enum LLEmptyStateStyle {
    case standard
    case minimal
    case feature

    var iconSize: CGFloat {
        switch self {
        case .standard: return 64
        case .minimal: return 48
        case .feature: return 80
        }
    }

    var spacing: CGFloat {
        switch self {
        case .standard: return LLSpacing.lg
        case .minimal: return LLSpacing.md
        case .feature: return LLSpacing.xl
        }
    }
}

/// Reusable empty state component
struct LLEmptyState: View {
    // MARK: - Properties

    let icon: String
    let title: String
    let message: String
    let style: LLEmptyStateStyle
    let actionTitle: String?
    let action: (() -> Void)?

    @Environment(\.colorScheme) var colorScheme

    // MARK: - Initializer

    init(
        icon: String,
        title: String,
        message: String,
        style: LLEmptyStateStyle = .standard,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.style = style
        self.actionTitle = actionTitle
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: style.spacing) {
            // Icon
            ZStack {
                Circle()
                    .fill(LLColors.muted.color(for: colorScheme).opacity(0.3))
                    .frame(width: style.iconSize + 32, height: style.iconSize + 32)

                Image(systemName: icon)
                    .font(.system(size: style.iconSize))
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    .symbolRenderingMode(.hierarchical)
            }

            // Text Content
            VStack(spacing: LLSpacing.xs) {
                Text(title)
                    .font(style == .feature ? LLTypography.h3() : LLTypography.h5())
                    .fontWeight(.semibold)
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(LLTypography.body())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, LLSpacing.lg)

            // Action Button
            if let actionTitle = actionTitle, let action = action {
                LLButton(actionTitle, style: .outline, size: .md, action: action)
                    .padding(.top, LLSpacing.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, style == .feature ? LLSpacing.xxxl : LLSpacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

// MARK: - Specialized Empty States

extension LLEmptyState {
    /// Empty state for no transactions
    static func noTransactions(action: @escaping () -> Void) -> some View {
        LLEmptyState(
            icon: "tray.fill",
            title: "No Transactions",
            message: "Your transaction history will appear here once you start using credits",
            actionTitle: "Get Credits",
            action: action
        )
    }

    /// Empty state for no credits
    static func noCredits(action: @escaping () -> Void) -> some View {
        LLEmptyState(
            icon: "dollarsign.circle.fill",
            title: "Out of Credits",
            message: "You've used all your credits. Purchase more to continue learning",
            style: .feature,
            actionTitle: "Buy Credits",
            action: action
        )
    }

    /// Empty state for no subscription
    static func noSubscription(action: @escaping () -> Void) -> some View {
        LLEmptyState(
            icon: "crown.fill",
            title: "No Active Subscription",
            message: "Upgrade to a paid plan to get monthly credits and unlock premium features",
            style: .feature,
            actionTitle: "View Plans",
            action: action
        )
    }
}

// MARK: - Preview

#Preview("Empty States") {
    ScrollView {
        VStack(spacing: LLSpacing.xxl) {
            LLCard(style: .standard) {
                LLEmptyState(
                    icon: "tray.fill",
                    title: "No Items",
                    message: "There are no items to display at this time"
                )
            }

            LLCard(style: .standard) {
                LLEmptyState(
                    icon: "exclamationmark.triangle.fill",
                    title: "Something Went Wrong",
                    message: "We couldn't load your data. Please try again",
                    actionTitle: "Retry",
                    action: { print("Retry tapped") }
                )
            }

            LLCard(style: .elevated) {
                LLEmptyState.noTransactions {
                    print("Get credits tapped")
                }
            }
        }
        .padding()
    }
}
