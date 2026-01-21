//
//  TransactionHistoryView.swift
//  LanguageLuid
//
//  Full transaction history with pagination and filtering
//

import SwiftUI

struct TransactionHistoryView: View {
    // MARK: - Properties

    @StateObject private var creditsViewModel = CreditsViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if creditsViewModel.isLoadingTransactions && creditsViewModel.transactions.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(LLSpacing.xl)
                } else if creditsViewModel.transactions.isEmpty {
                    emptyState
                } else {
                    transactionsList
                }
            }
            .padding(.horizontal, LLSpacing.lg)
            .padding(.top, LLSpacing.md)
            .padding(.bottom, LLSpacing.xxxl)
        }
        .background(LLColors.background.color(for: colorScheme))
        .navigationTitle("Transaction History")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await creditsViewModel.loadTransactions(refresh: true)
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
    }

    // MARK: - Empty State

    private var emptyState: some View {
        LLCard(style: .standard, padding: .none) {
            LLEmptyState(
                icon: "tray.fill",
                title: "No Transactions",
                message: "Your transaction history will appear here once you start using credits",
                style: .standard
            )
        }
        .padding(.top, LLSpacing.xl)
    }

    // MARK: - Transactions List

    private var transactionsList: some View {
        VStack(spacing: LLSpacing.md) {
            // Group transactions by month
            ForEach(groupedTransactions.keys.sorted(by: >), id: \.self) { monthKey in
                if let transactions = groupedTransactions[monthKey] {
                    transactionSection(
                        title: monthKey,
                        transactions: transactions
                    )
                }
            }

            // Load more indicator
            if creditsViewModel.hasMoreTransactions {
                loadMoreButton
            }
        }
    }

    // MARK: - Transaction Section

    private func transactionSection(title: String, transactions: [CreditTransaction]) -> some View {
        VStack(alignment: .leading, spacing: LLSpacing.sm) {
            // Section Header
            Text(title)
                .font(LLTypography.h6())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                .padding(.horizontal, LLSpacing.xs)

            // Transactions
            VStack(spacing: 0) {
                ForEach(Array(transactions.enumerated()), id: \.element.id) { index, transaction in
                    TransactionDetailRow(transaction: transaction)

                    if index < transactions.count - 1 {
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

    // MARK: - Load More Button

    private var loadMoreButton: some View {
        Group {
            if creditsViewModel.isLoadingTransactions {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(LLSpacing.md)
            } else {
                LLButton("Load More", style: .outline, fullWidth: true) {
                    Task {
                        await creditsViewModel.loadTransactions(refresh: false)
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    /// Group transactions by month for better organization
    private var groupedTransactions: [String: [CreditTransaction]] {
        Dictionary(grouping: creditsViewModel.transactions) { transaction in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: transaction.createdAt)
        }
    }
}

// MARK: - Transaction Detail Row

struct TransactionDetailRow: View {
    let transaction: CreditTransaction
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: LLSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 40, height: 40)

                Image(systemName: transaction.type.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(LLTypography.bodyMedium())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))

                HStack(spacing: LLSpacing.xs) {
                    Text(transaction.dateDisplay)
                        .font(LLTypography.caption())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                    if let metadata = transaction.metadata, !metadata.isEmpty {
                        Text("•")
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                        Text(metadataDisplay)
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                }

                // Balance change
                HStack(spacing: 4) {
                    Text("Balance:")
                        .font(LLTypography.caption())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                    Text("\(transaction.balanceBefore)")
                        .font(LLTypography.caption())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                    Image(systemName: "arrow.right")
                        .font(.system(size: 8))
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                    Text("\(transaction.balanceAfter)")
                        .font(LLTypography.caption())
                        .fontWeight(.semibold)
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))
                }
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.formattedAmount)
                    .font(LLTypography.h6())
                    .foregroundColor(amountColor)

                typeLabel
            }
        }
        .padding(LLSpacing.md)
    }

    // MARK: - Computed Properties

    private var iconColor: Color {
        switch transaction.type {
        case .usage, .refund:
            return LLColors.destructive.color(for: colorScheme)
        case .purchase, .subscription, .promotional, .bonus, .reset:
            return LLColors.primary.color(for: colorScheme)
        }
    }

    private var iconBackgroundColor: Color {
        iconColor.opacity(0.1)
    }

    private var amountColor: Color {
        transaction.type.isDebit
            ? LLColors.destructive.color(for: colorScheme)
            : LLColors.primary.color(for: colorScheme)
    }

    private var typeLabel: some View {
        Text(transaction.type.rawValue.capitalized)
            .font(LLTypography.caption())
            .fontWeight(.medium)
            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(LLColors.muted.color(for: colorScheme))
            )
    }

    private var metadataDisplay: String {
        guard let metadata = transaction.metadata else { return "" }

        var parts: [String] = []

        if let amount = metadata["amount"], let currency = metadata["currency"] {
            parts.append("\(currency) \(amount)")
        }

        if let lesson = metadata["lesson"] {
            parts.append(lesson)
        }

        if let reason = metadata["reason"] {
            parts.append(reason)
        }

        return parts.joined(separator: " • ")
    }
}

// MARK: - Preview

#Preview("Transaction History") {
    NavigationStack {
        TransactionHistoryView()
    }
}

#Preview("Empty State") {
    NavigationStack {
        TransactionHistoryView()
    }
}
