//
//  SubscriptionManagementView.swift
//  LanguageLuid
//
//  Subscription management with upgrade, cancel, and reactivate options
//

import SwiftUI

struct SubscriptionManagementView: View {
    // MARK: - Properties

    @StateObject private var creditsViewModel = CreditsViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    // MARK: - State

    @State private var showingCancelAlert = false
    @State private var showingReactivateAlert = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: LLSpacing.xl) {
                if creditsViewModel.isLoading {
                    // Loading skeleton
                    VStack(spacing: LLSpacing.lg) {
                        LLSkeletonLoader(shape: .roundedRectangle(width: nil, height: 200, cornerRadius: LLSpacing.radiusLG))
                        LLSkeletonLoader(shape: .roundedRectangle(width: nil, height: 150, cornerRadius: LLSpacing.radiusLG))
                    }
                } else if let subscription = creditsViewModel.subscription {
                    // Current Subscription Card
                    currentSubscriptionCard(subscription)

                    // Actions
                    subscriptionActions(subscription)

                    // Billing Portal Button
                    billingPortalSection
                } else {
                    // No subscription - show upgrade options
                    upgradeOptions
                }
            }
            .padding(.horizontal, LLSpacing.lg)
            .padding(.top, LLSpacing.md)
            .padding(.bottom, LLSpacing.xxxl)
        }
        .background(LLColors.background.color(for: colorScheme))
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await creditsViewModel.refreshAll()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(LLColors.primary.color(for: colorScheme))
                }
                .disabled(creditsViewModel.isLoading)
            }
        }
        .alert("Cancel Subscription", isPresented: $showingCancelAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm Cancellation", role: .destructive) {
                Task {
                    await creditsViewModel.cancelSubscription()
                }
            }
        } message: {
            Text("Your subscription will remain active until the end of the current billing period. You won't be charged again.")
        }
        .alert("Reactivate Subscription", isPresented: $showingReactivateAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reactivate", role: .none) {
                Task {
                    await creditsViewModel.reactivateSubscription()
                }
            }
        } message: {
            Text("Your subscription will continue and you'll be charged at the end of the current period.")
        }
        .alert("Error", isPresented: .constant(creditsViewModel.errorMessage != nil)) {
            Button("OK") {
                creditsViewModel.clearError()
            }
        } message: {
            if let error = creditsViewModel.errorMessage {
                Text(error)
            }
        }
        .alert("Success", isPresented: .constant(creditsViewModel.successMessage != nil)) {
            Button("OK") {
                creditsViewModel.successMessage = nil
            }
        } message: {
            if let success = creditsViewModel.successMessage {
                Text(success)
            }
        }
    }

    // MARK: - Current Subscription Card

    private func currentSubscriptionCard(_ subscription: Subscription) -> some View {
        LLCard(style: .elevated, padding: .lg) {
            VStack(spacing: LLSpacing.lg) {
                // Plan Header
                HStack {
                    VStack(alignment: .leading, spacing: LLSpacing.xs) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(LLColors.primary.color(for: colorScheme))

                            Text(subscription.plan.displayName)
                                .font(LLTypography.h4())
                                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                        }

                        Text(subscription.plan.monthlyCredits == 1000 ? "1000 credits/month" : "\(subscription.plan.monthlyCredits) credits/month")
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }

                    Spacer()

                    if subscription.status.isActive {
                        LLBadge("Active", variant: .success)
                    } else {
                        LLBadge(subscription.status.displayName, variant: .secondary)
                    }
                }

                Divider()

                // Subscription Details
                VStack(spacing: LLSpacing.sm) {
                    subscriptionDetailRow(
                        label: "Status",
                        value: subscription.status.displayName,
                        icon: subscription.status.isActive ? "checkmark.circle.fill" : "info.circle"
                    )

                    subscriptionDetailRow(
                        label: subscription.cancelAtPeriodEnd ? "Active Until" : "Renews",
                        value: subscription.currentPeriodEnd.formatted(date: .abbreviated, time: .omitted),
                        icon: "calendar"
                    )

                    if let message = creditsViewModel.renewalMessage {
                        subscriptionDetailRow(
                            label: "Next Action",
                            value: message,
                            icon: "clock"
                        )
                    }
                }

                // Cancellation Notice
                if subscription.cancelAtPeriodEnd {
                    VStack(alignment: .leading, spacing: LLSpacing.xs) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(LLColors.destructive.color(for: colorScheme))

                            Text("Subscription Cancelling")
                                .font(LLTypography.bodyMedium())
                                .foregroundColor(LLColors.destructive.color(for: colorScheme))
                        }

                        Text("Your subscription will end on \(subscription.currentPeriodEnd.formatted(date: .abbreviated, time: .omitted)). Reactivate to continue.")
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                    .padding(LLSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                            .fill(LLColors.destructive.color(for: colorScheme).opacity(0.1))
                    )
                }
            }
        }
    }

    // MARK: - Subscription Actions

    private func subscriptionActions(_ subscription: Subscription) -> some View {
        VStack(spacing: LLSpacing.md) {
            if subscription.status.isActive {
                if subscription.cancelAtPeriodEnd {
                    // Show reactivate button
                    LLButton("Reactivate Subscription", style: .primary, fullWidth: true) {
                        showingReactivateAlert = true
                    }
                    .disabled(creditsViewModel.isCancelling)
                } else {
                    // Show cancel button
                    LLButton("Cancel Subscription", style: .destructive, fullWidth: true) {
                        showingCancelAlert = true
                    }
                    .disabled(creditsViewModel.isCancelling)
                }
            }

            // Upgrade/Downgrade options (if needed)
            if subscription.plan != .yearly {
                upgradeToYearlySection
            }
        }
    }

    // MARK: - Billing Portal Section

    private var billingPortalSection: some View {
        LLCard(style: .standard, padding: .lg) {
            VStack(alignment: .leading, spacing: LLSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: LLSpacing.xs) {
                        Text("Billing Portal")
                            .font(LLTypography.h6())
                            .foregroundColor(LLColors.foreground.color(for: colorScheme))

                        Text("Manage payment methods, invoices, and billing details")
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }

                LLButton("Open Billing Portal", style: .outline, fullWidth: true) {
                    Task {
                        await creditsViewModel.openBillingPortal()
                    }
                }
            }
        }
    }

    // MARK: - Upgrade to Yearly Section

    private var upgradeToYearlySection: some View {
        LLCard(style: .elevated, padding: .lg) {
            VStack(spacing: LLSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: LLSpacing.xs) {
                        HStack {
                            Text("Upgrade to Yearly")
                                .font(LLTypography.h6())
                                .foregroundColor(LLColors.foreground.color(for: colorScheme))

                            LLBadge("Save 17%", variant: .success)
                        }

                        Text("Get 12 months for the price of 10")
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }

                    Spacer()

                    Text("$99/yr")
                        .font(LLTypography.h6())
                        .foregroundColor(LLColors.primary.color(for: colorScheme))
                }

                LLButton("Upgrade to Yearly", style: .primary, fullWidth: true) {
                    Task {
                        await creditsViewModel.upgradeToYearly()
                    }
                }
                .disabled(creditsViewModel.isPurchasing)
            }
        }
    }

    // MARK: - Upgrade Options (No Subscription)

    private var upgradeOptions: some View {
        VStack(spacing: LLSpacing.lg) {
            // Header
            VStack(spacing: LLSpacing.sm) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundColor(LLColors.primary.color(for: colorScheme))

                Text("Choose Your Plan")
                    .font(LLTypography.h3())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))

                Text("Unlock unlimited learning")
                    .font(LLTypography.body())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
            .padding(.vertical, LLSpacing.lg)

            // Monthly Plan
            planCard(
                name: "Pro Monthly",
                price: "$10",
                period: "/month",
                credits: "1000 credits/month",
                features: [
                    "1000 monthly credits",
                    "All premium features",
                    "Cancel anytime",
                    "Priority support"
                ]
            ) {
                Task {
                    await creditsViewModel.upgradeToPro()
                }
            }

            // Yearly Plan
            planCard(
                name: "Pro Yearly",
                price: "$99",
                period: "/year",
                credits: "1000 credits/month",
                badge: "Save 17%",
                features: [
                    "12000 credits/year",
                    "All premium features",
                    "2 months free",
                    "Priority support"
                ]
            ) {
                Task {
                    await creditsViewModel.upgradeToYearly()
                }
            }
        }
    }

    // MARK: - Helper Views

    private func subscriptionDetailRow(label: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                .frame(width: 24)

            Text(label)
                .font(LLTypography.body())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

            Spacer()

            Text(value)
                .font(LLTypography.bodyMedium())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
        }
    }

    private func planCard(
        name: String,
        price: String,
        period: String,
        credits: String,
        badge: String? = nil,
        features: [String],
        action: @escaping () -> Void
    ) -> some View {
        LLCard(style: .elevated, padding: .lg) {
            VStack(spacing: LLSpacing.lg) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: LLSpacing.xs) {
                        HStack {
                            Text(name)
                                .font(LLTypography.h5())
                                .foregroundColor(LLColors.foreground.color(for: colorScheme))

                            if let badge = badge {
                                LLBadge(badge, variant: .success)
                            }
                        }

                        Text(credits)
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }

                    Spacer()

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(price)
                            .font(LLTypography.h3())
                            .foregroundColor(LLColors.primary.color(for: colorScheme))

                        Text(period)
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                }

                Divider()

                // Features
                VStack(alignment: .leading, spacing: LLSpacing.sm) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: LLSpacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(LLColors.primary.color(for: colorScheme))
                                .frame(width: 20)

                            Text(feature)
                                .font(LLTypography.body())
                                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                        }
                    }
                }

                // Action Button
                LLButton("Subscribe Now", style: .primary, fullWidth: true, action: action)
                    .disabled(creditsViewModel.isPurchasing)
            }
        }
    }
}

// MARK: - Preview

#Preview("With Subscription") {
    NavigationStack {
        SubscriptionManagementView()
    }
}

#Preview("No Subscription") {
    NavigationStack {
        SubscriptionManagementView()
    }
}
