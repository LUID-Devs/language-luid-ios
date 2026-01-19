//
//  CreditBalanceCard.swift
//  LanguageLuid
//
//  Credit balance display card with breakdown and refresh
//

import SwiftUI

struct CreditBalanceCard: View {
    // MARK: - Properties

    @ObservedObject var creditsViewModel: CreditsViewModel

    // MARK: - State

    @Environment(\.colorScheme) var colorScheme
    @State private var showBreakdown: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Credits")
                        .font(.headline)
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))

                    if let credits = creditsViewModel.credits {
                        Text("\(credits.totalCredits) available")
                            .font(.caption)
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                }

                Spacer()

                // Refresh button
                Button(action: refreshCredits) {
                    Image(systemName: "arrow.clockwise")
                        .font(.body)
                        .foregroundColor(LLColors.primary.color(for: colorScheme))
                }
                .buttonStyle(.plain)
                .disabled(creditsViewModel.isLoading)
            }

            if creditsViewModel.isLoading {
                // Loading state
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if let credits = creditsViewModel.credits {
                // Credit balance display
                creditBalanceView(credits)
            } else {
                // Error or no data
                Text("Unable to load credits")
                    .font(.caption)
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LLColors.card.color(for: colorScheme))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .onAppear {
            if creditsViewModel.credits == nil {
                Task {
                    await creditsViewModel.loadCredits()
                }
            }
        }
    }

    // MARK: - Credit Balance View

    private func creditBalanceView(_ credits: CreditBalance) -> some View {
        VStack(spacing: 16) {
            // Total credits - Large display
            VStack(spacing: 4) {
                Text("\(credits.totalCredits)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(LLColors.primary.color(for: colorScheme))

                Text("Total Credits")
                    .font(.caption)
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
            .frame(maxWidth: .infinity)

            // Breakdown toggle
            Button(action: { withAnimation { showBreakdown.toggle() } }) {
                HStack(spacing: 8) {
                    Text(showBreakdown ? "Hide Breakdown" : "Show Breakdown")
                        .font(.caption)
                        .fontWeight(.medium)

                    Image(systemName: showBreakdown ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(LLColors.primary.color(for: colorScheme))
            }
            .buttonStyle(.plain)

            // Breakdown details (expandable)
            if showBreakdown {
                VStack(spacing: 12) {
                    Divider()

                    creditBreakdownRow(
                        icon: "calendar.circle.fill",
                        label: "Subscription",
                        amount: credits.subscriptionCredits,
                        color: .blue
                    )

                    creditBreakdownRow(
                        icon: "cart.circle.fill",
                        label: "Purchased",
                        amount: credits.purchasedCredits,
                        color: .green
                    )

                    creditBreakdownRow(
                        icon: "gift.circle.fill",
                        label: "Promotional",
                        amount: credits.promotionalCredits,
                        color: .purple
                    )
                }
                .transition(.opacity)
            }

            // Subscription info
            if let subscription = creditsViewModel.subscription {
                Divider()

                subscriptionInfoView(subscription)
            }
        }
    }

    // MARK: - Credit Breakdown Row

    private func creditBreakdownRow(
        icon: String,
        label: String,
        amount: Int,
        color: Color
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(label)
                .font(.subheadline)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            Spacer()

            Text("\(amount)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Subscription Info

    private func subscriptionInfoView(_ subscription: Subscription) -> some View {
        VStack(spacing: 8) {
            HStack {
                Label(subscription.plan.displayName, systemImage: "crown.fill")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(LLColors.primary.color(for: colorScheme))

                Spacer()

                if subscription.status == .active {
                    Label("Active", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                } else {
                    Label(subscription.status.displayName, systemImage: "info.circle")
                        .font(.caption2)
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
            }

            if let resetDate = creditsViewModel.credits?.nextReset {
                HStack {
                    Text("Resets:")
                        .font(.caption2)
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                    Spacer()

                    Text(resetDate, style: .relative)
                        .font(.caption2)
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(LLColors.primary.color(for: colorScheme).opacity(0.05))
        )
    }

    // MARK: - Actions

    private func refreshCredits() {
        Task {
            await creditsViewModel.loadCredits()
            await creditsViewModel.loadSubscription()
        }
    }
}

// MARK: - Preview
// TODO: Fix previews - cannot set @Published properties with private setters
/*
#Preview("With Credits") {
    let viewModel = CreditsViewModel()
    // Simulate loaded credits
    viewModel.credits = CreditBalance(
        total: 850,
        subscription: 500,
        purchased: 250,
        promotional: 100,
        nextReset: Date().addingTimeInterval(86400 * 5) // 5 days from now
    )
    viewModel.subscription = Subscription(
        id: "sub_123",
        userId: "user_123",
        planId: "pro",
        status: .active,
        currentPeriodStart: Date().addingTimeInterval(-86400 * 25),
        currentPeriodEnd: Date().addingTimeInterval(86400 * 5),
        cancelAtPeriodEnd: false,
        stripeSubscriptionId: "sub_stripe_123"
    )

    return CreditBalanceCard(creditsViewModel: viewModel)
        .padding()
}

#Preview("Loading") {
    let viewModel = CreditsViewModel()
    viewModel.isLoading = true

    return CreditBalanceCard(creditsViewModel: viewModel)
        .padding()
}

#Preview("No Credits") {
    let viewModel = CreditsViewModel()
    viewModel.credits = CreditBalance(
        total: 0,
        subscription: 0,
        purchased: 0,
        promotional: 0,
        nextReset: Date().addingTimeInterval(86400 * 30)
    )

    return CreditBalanceCard(creditsViewModel: viewModel)
        .padding()
}
*/
