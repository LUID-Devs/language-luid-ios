//
//  CreditsDetailView.swift
//  LanguageLuid
//
//  Full credits management view with balance, purchase options, and transactions
//

import SwiftUI

struct CreditsDetailView: View {
    // MARK: - Properties

    @StateObject private var creditsViewModel = CreditsViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    // MARK: - State

    @State private var showingPurchaseSheet = false
    @State private var selectedPurchaseAmount: Int?

    // MARK: - Purchase Options

    private let purchaseOptions: [(amount: Int, price: String, perCredit: String)] = [
        (100, "$4.99", "$0.05"),
        (250, "$9.99", "$0.04"),
        (500, "$19.99", "$0.04"),
        (1000, "$34.99", "$0.03")
    ]

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: LLSpacing.lg) {
                // Credit Balance Card
                creditBalanceCard

                // Subscription Card (if applicable)
                if creditsViewModel.subscription != nil {
                    subscriptionCard
                }

                // Purchase Credits Section (if free plan)
                if !creditsViewModel.isPaidPlan {
                    purchaseCreditsSection
                }

                // Upgrade to Pro Section (if free plan)
                if !creditsViewModel.isPaidPlan {
                    upgradeToProSection
                }

                // Recent Transactions
                recentTransactionsSection
            }
            .padding(.horizontal, LLSpacing.lg)
            .padding(.top, LLSpacing.md)
            .padding(.bottom, LLSpacing.xxxl)
        }
        .background(LLColors.background.color(for: colorScheme))
        .navigationTitle("Credits")
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
        .refreshable {
            await creditsViewModel.refreshAll()
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
        .sheet(isPresented: $showingPurchaseSheet) {
            if let amount = selectedPurchaseAmount {
                purchaseConfirmationSheet(amount: amount)
            }
        }
    }

    // MARK: - Credit Balance Card

    private var creditBalanceCard: some View {
        LLCard(style: .elevated, padding: .lg) {
            if creditsViewModel.isLoading && creditsViewModel.credits == nil {
                LLCreditCardSkeleton()
            } else if let credits = creditsViewModel.credits {
                VStack(spacing: LLSpacing.lg) {
                    // Total Credits - Large Display with animation
                    VStack(spacing: LLSpacing.sm) {
                        Text("\(credits.totalCredits)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundColor(LLColors.primary.color(for: colorScheme))
                            .contentTransition(.numericText())

                        Text("Total Credits Available")
                            .font(LLTypography.bodySmall())
                            .fontWeight(.medium)
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                            .textCase(.uppercase)
                            .tracking(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LLSpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        LLColors.primary.color(for: colorScheme).opacity(0.08),
                                        LLColors.primary.color(for: colorScheme).opacity(0.03)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )

                    // Breakdown with enhanced visual hierarchy
                    VStack(spacing: LLSpacing.md) {
                        creditBreakdownRow(
                            icon: "calendar.circle.fill",
                            label: "Subscription Credits",
                            value: creditsViewModel.subscriptionCreditsDisplay,
                            color: Color.blue
                        )

                        creditBreakdownRow(
                            icon: "cart.circle.fill",
                            label: "Purchased Credits",
                            value: creditsViewModel.purchasedCreditsDisplay,
                            color: Color.green
                        )

                        creditBreakdownRow(
                            icon: "gift.circle.fill",
                            label: "Promotional Credits",
                            value: creditsViewModel.promotionalCreditsDisplay,
                            color: Color.purple
                        )
                    }

                    // Reset Info with better visual treatment
                    if let _ = credits.nextReset {
                        Divider()
                            .padding(.vertical, LLSpacing.xs)

                        HStack(spacing: LLSpacing.sm) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 16))
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                            Text("Credits reset \(creditsViewModel.daysUntilReset)")
                                .font(LLTypography.bodySmall())
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                            Spacer()
                        }
                    }
                }
            } else {
                LLEmptyState(
                    icon: "exclamationmark.triangle.fill",
                    title: "Unable to Load Credits",
                    message: "There was an error loading your credit balance. Please try again.",
                    style: .minimal,
                    actionTitle: "Retry",
                    action: {
                        Task {
                            await creditsViewModel.refreshAll()
                        }
                    }
                )
            }
        }
    }

    // MARK: - Subscription Card

    private var subscriptionCard: some View {
        LLCard(style: .standard, padding: .lg) {
            if let subscription = creditsViewModel.subscription {
                VStack(alignment: .leading, spacing: LLSpacing.md) {
                    HStack {
                        Label(subscription.plan.displayName, systemImage: "crown.fill")
                            .font(LLTypography.h5())
                            .foregroundColor(LLColors.primary.color(for: colorScheme))

                        Spacer()

                        if subscription.status.isActive {
                            LLBadge("Active", variant: .success)
                        } else {
                            LLBadge(subscription.status.displayName, variant: .secondary)
                        }
                    }

                    if let renewalMessage = creditsViewModel.renewalMessage {
                        Text(renewalMessage)
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }

                    NavigationLink {
                        SubscriptionManagementView()
                    } label: {
                        Text("Manage Subscription")
                            .font(LLTypography.bodyMedium())
                            .foregroundColor(LLColors.primary.color(for: colorScheme))
                    }
                }
            }
        }
    }

    // MARK: - Purchase Credits Section

    private var purchaseCreditsSection: some View {
        VStack(alignment: .leading, spacing: LLSpacing.md) {
            Text("Purchase Credits")
                .font(LLTypography.h4())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            VStack(spacing: LLSpacing.sm) {
                ForEach(purchaseOptions, id: \.amount) { option in
                    purchaseOptionButton(option)
                }
            }
        }
    }

    // MARK: - Upgrade to Pro Section

    private var upgradeToProSection: some View {
        LLCard(style: .elevated, padding: .lg) {
            VStack(spacing: LLSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: LLSpacing.xs) {
                        Label("Upgrade to Pro", systemImage: "crown.fill")
                            .font(LLTypography.h5())
                            .foregroundColor(LLColors.primary.color(for: colorScheme))

                        Text("Get 1000 credits monthly")
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }

                    Spacer()

                    Text("$10/mo")
                        .font(LLTypography.h5())
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))
                }

                LLButton("Upgrade Now", style: .primary, fullWidth: true) {
                    Task {
                        await creditsViewModel.upgradeToPro()
                    }
                }
                .disabled(creditsViewModel.isPurchasing)
            }
        }
    }

    // MARK: - Recent Transactions

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: LLSpacing.md) {
            HStack {
                Text("Recent Transactions")
                    .font(LLTypography.h4())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))

                Spacer()

                NavigationLink {
                    TransactionHistoryView()
                } label: {
                    Text("See All")
                        .font(LLTypography.body())
                        .foregroundColor(LLColors.primary.color(for: colorScheme))
                }
            }

            if creditsViewModel.isLoadingTransactions {
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { index in
                        LLTransactionRowSkeleton()
                        if index < 2 {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: LLSpacing.radiusLG)
                        .fill(LLColors.card.color(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LLSpacing.radiusLG)
                        .stroke(LLColors.border.color(for: colorScheme), lineWidth: 1)
                )
            } else if creditsViewModel.transactions.isEmpty {
                LLCard(style: .standard, padding: .none) {
                    LLEmptyState(
                        icon: "tray.fill",
                        title: "No Transactions",
                        message: "Your transaction history will appear here once you start using credits",
                        style: .minimal
                    )
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(creditsViewModel.transactions.prefix(5).enumerated()), id: \.element.id) { index, transaction in
                        TransactionRow(transaction: transaction)

                        if index < min(4, creditsViewModel.transactions.count - 1) {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: LLSpacing.radiusLG)
                        .fill(LLColors.card.color(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LLSpacing.radiusLG)
                        .stroke(LLColors.border.color(for: colorScheme), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Helper Views

    private func creditBreakdownRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: LLSpacing.md) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(LLTypography.bodySmall())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                Text(value)
                    .font(LLTypography.h6())
                    .fontWeight(.semibold)
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
            }

            Spacer()
        }
        .padding(LLSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: LLSpacing.radiusSM)
                .fill(LLColors.muted.color(for: colorScheme).opacity(0.3))
        )
    }

    private func purchaseOptionButton(_ option: (amount: Int, price: String, perCredit: String)) -> some View {
        Button {
            selectedPurchaseAmount = option.amount
            showingPurchaseSheet = true
        } label: {
            HStack(spacing: LLSpacing.md) {
                // Credit amount icon
                ZStack {
                    RoundedRectangle(cornerRadius: LLSpacing.radiusSM)
                        .fill(LLColors.primary.color(for: colorScheme).opacity(0.1))
                        .frame(width: 48, height: 48)

                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(LLColors.primary.color(for: colorScheme))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(option.amount) Credits")
                        .font(LLTypography.h6())
                        .fontWeight(.semibold)
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))

                    Text("\(option.perCredit) per credit")
                        .font(LLTypography.caption())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(option.price)
                        .font(LLTypography.h5())
                        .fontWeight(.bold)
                        .foregroundColor(LLColors.primary.color(for: colorScheme))

                    if option.amount >= 500 {
                        LLBadge("Best Value", variant: .success, size: .sm)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
            .padding(LLSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                    .fill(LLColors.card.color(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                    .stroke(
                        option.amount >= 500
                            ? LLColors.primary.color(for: colorScheme).opacity(0.3)
                            : LLColors.border.color(for: colorScheme),
                        lineWidth: option.amount >= 500 ? 2 : 1
                    )
            )
            .shadow(
                color: Color.black.opacity(0.03),
                radius: 4,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(.plain)
        .disabled(creditsViewModel.isPurchasing)
    }

    private func purchaseConfirmationSheet(amount: Int) -> some View {
        NavigationStack {
            VStack(spacing: LLSpacing.xl) {
                Image(systemName: "creditcard.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(LLColors.primary.color(for: colorScheme))

                VStack(spacing: LLSpacing.sm) {
                    Text("Purchase \(amount) Credits")
                        .font(LLTypography.h3())
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))

                    Text("You'll be redirected to complete your purchase securely via Stripe")
                        .font(LLTypography.body())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        .multilineTextAlignment(.center)
                }

                Spacer()

                VStack(spacing: LLSpacing.sm) {
                    LLButton("Continue to Checkout", style: .primary, fullWidth: true) {
                        Task {
                            await creditsViewModel.purchaseCredits(amount: amount)
                            showingPurchaseSheet = false
                        }
                    }
                    .disabled(creditsViewModel.isPurchasing)

                    LLButton("Cancel", style: .ghost, fullWidth: true) {
                        showingPurchaseSheet = false
                    }
                }
            }
            .padding(LLSpacing.xl)
            .navigationTitle("Confirm Purchase")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.height(400)])
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: CreditTransaction
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: LLSpacing.md) {
            // Icon
            Image(systemName: transaction.type.icon)
                .font(.title3)
                .foregroundColor(transaction.type.isDebit ? LLColors.destructive.color(for: colorScheme) : LLColors.primary.color(for: colorScheme))
                .frame(width: 32)

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(LLTypography.body())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))

                Text(transaction.dateDisplay)
                    .font(LLTypography.caption())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }

            Spacer()

            // Amount
            Text(transaction.formattedAmount)
                .font(LLTypography.bodyMedium())
                .foregroundColor(transaction.type.isDebit ? LLColors.destructive.color(for: colorScheme) : LLColors.primary.color(for: colorScheme))
        }
        .padding(LLSpacing.md)
    }
}

// MARK: - Preview

#Preview("Credits Detail") {
    NavigationStack {
        CreditsDetailView()
    }
}
