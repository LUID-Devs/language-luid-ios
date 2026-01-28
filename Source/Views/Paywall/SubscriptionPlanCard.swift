//
//  PaywallPlanCard.swift
//  LanguageLuid
//
//  Subscription plan card component for paywall
//

import SwiftUI

struct PaywallPlanCard: View {
    // MARK: - Properties

    let plan: PaywallPlan
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false

    // MARK: - Body

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Header with badge
                if plan.isPopular || plan.savings != nil {
                    headerBadge
                }

                // Main content
                VStack(alignment: .leading, spacing: LLSpacing.md) {
                    // Plan name and price
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: LLSpacing.xs) {
                            Text(plan.name)
                                .font(LLTypography.h3())
                                .fontWeight(.bold)
                                .foregroundColor(LLColors.foreground.color(for: colorScheme))

                            Text(plan.duration)
                                .font(LLTypography.bodySmall())
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }

                        Spacer()

                        // Price
                        VStack(alignment: .trailing, spacing: LLSpacing.xs) {
                            Text(plan.price)
                                .font(LLTypography.h2())
                                .fontWeight(.bold)
                                .foregroundColor(LLColors.primary.color(for: colorScheme))

                            if let pricePerMonth = plan.pricePerMonth {
                                Text(pricePerMonth)
                                    .font(LLTypography.captionSmall())
                                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                            }
                        }
                    }

                    // Savings badge
                    if let savings = plan.savings {
                        HStack {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 12))
                            Text(savings)
                                .font(LLTypography.captionSmall())
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(LLColors.successForeground.color(for: colorScheme))
                        .padding(.horizontal, LLSpacing.sm)
                        .padding(.vertical, LLSpacing.xs)
                        .background(
                            Capsule()
                                .fill(LLColors.success.color(for: colorScheme).opacity(0.2))
                        )
                    }

                    // Features (show first 3)
                    if !plan.features.isEmpty {
                        VStack(alignment: .leading, spacing: LLSpacing.xs) {
                            ForEach(plan.features.prefix(3), id: \.self) { feature in
                                FeatureRow(feature: feature, isCompact: true)
                            }

                            if plan.features.count > 3 {
                                Text("+ \(plan.features.count - 3) more features")
                                    .font(LLTypography.captionSmall())
                                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                    .padding(.leading, 24)
                            }
                        }
                    }
                }
                .padding(LLSpacing.md)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                    .fill(cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
            .shadow(
                color: isSelected ? LLColors.primary.color(for: colorScheme).opacity(0.2) : Color.clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    // MARK: - Header Badge

    private var headerBadge: some View {
        HStack {
            if plan.isPopular {
                HStack(spacing: LLSpacing.xs) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                    Text("MOST POPULAR")
                        .font(LLTypography.captionSmall())
                        .fontWeight(.bold)
                }
                .foregroundColor(LLColors.primaryForeground.color(for: colorScheme))
                .padding(.horizontal, LLSpacing.sm)
                .padding(.vertical, LLSpacing.xs)
                .frame(maxWidth: .infinity)
                .background(LLColors.primary.color(for: colorScheme))
            } else if let savings = plan.savings {
                HStack(spacing: LLSpacing.xs) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 12))
                    Text(savings.uppercased())
                        .font(LLTypography.captionSmall())
                        .fontWeight(.bold)
                }
                .foregroundColor(LLColors.successForeground.color(for: colorScheme))
                .padding(.horizontal, LLSpacing.sm)
                .padding(.vertical, LLSpacing.xs)
                .frame(maxWidth: .infinity)
                .background(LLColors.success.color(for: colorScheme))
            }
        }
        .clipShape(
            .rect(
                topLeadingRadius: LLSpacing.radiusMD,
                topTrailingRadius: LLSpacing.radiusMD
            )
        )
    }

    // MARK: - Computed Properties

    private var cardBackground: Color {
        if isSelected {
            return LLColors.card.color(for: colorScheme)
        } else {
            return LLColors.muted.color(for: colorScheme).opacity(0.3)
        }
    }

    private var borderColor: Color {
        if isSelected {
            return LLColors.primary.color(for: colorScheme)
        } else {
            return LLColors.border.color(for: colorScheme)
        }
    }

    private var borderWidth: CGFloat {
        isSelected ? 2 : 1
    }
}

// MARK: - Feature Row Component

private struct FeatureRow: View {
    let feature: String
    let isCompact: Bool

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: LLSpacing.xs) {
            Image(systemName: "checkmark")
                .font(.system(size: isCompact ? 12 : 14))
                .foregroundColor(LLColors.success.color(for: colorScheme))
                .frame(width: 16)

            Text(feature)
                .font(isCompact ? LLTypography.captionSmall() : LLTypography.bodySmall())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("Plan Card - Selected") {
    VStack(spacing: LLSpacing.md) {
        PaywallPlanCard(
            plan: .annual,
            isSelected: true,
            action: {}
        )

        PaywallPlanCard(
            plan: .monthly,
            isSelected: false,
            action: {}
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Plan Card - Dark Mode") {
    VStack(spacing: LLSpacing.md) {
        PaywallPlanCard(
            plan: .annual,
            isSelected: true,
            action: {}
        )

        PaywallPlanCard(
            plan: .monthly,
            isSelected: false,
            action: {}
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .preferredColorScheme(.dark)
}
