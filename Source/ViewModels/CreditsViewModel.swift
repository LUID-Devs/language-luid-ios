//
//  CreditsViewModel.swift
//  LanguageLuid
//
//  ViewModel for managing credits and subscription state
//  Handles credit balance, subscription info, transactions, and purchases
//

import Foundation
import Combine
import os.log
#if os(iOS)
import UIKit
#endif

/// Credits and subscription view model
@MainActor
class CreditsViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Current credit balance
    @Published private(set) var credits: CreditBalance?

    /// Current subscription details
    @Published private(set) var subscription: Subscription?

    /// Loading state for async operations
    @Published private(set) var isLoading = false

    /// Loading state for specific operations
    @Published private(set) var isLoadingTransactions = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var isCancelling = false

    /// Error message to display
    @Published var errorMessage: String?

    /// Success message to display
    @Published var successMessage: String?

    /// Transaction history
    @Published private(set) var transactions: [CreditTransaction] = []

    /// Pagination state for transactions
    @Published private(set) var hasMoreTransactions = true
    @Published private(set) var currentPage = 1

    // MARK: - Dependencies

    private let subscriptionService: SubscriptionService
    private let logger = OSLog(subsystem: "com.luid.languageluid", category: "CreditsViewModel")

    // MARK: - Private State

    private var cancellables = Set<AnyCancellable>()
    private let transactionsPerPage = 50

    // MARK: - Initialization

    /// Initialize CreditsViewModel with dependency injection
    /// - Parameter subscriptionService: Subscription service (defaults to shared instance)
    init(subscriptionService: SubscriptionService = .shared) {
        self.subscriptionService = subscriptionService

        // Auto-load data on initialization
        Task {
            await refreshAll()
        }
    }

    // MARK: - Data Loading

    /// Load credit balance from server
    func loadCredits() async {
        print("💳 CreditsViewModel: Loading credit balance...")

        isLoading = true
        clearError()

        do {
            credits = try await subscriptionService.fetchCredits()
            print("✅ CreditsViewModel: Credits loaded - \(credits?.totalCredits ?? 0) total")
        } catch let error as SubscriptionError {
            handleError(error)
            print("❌ CreditsViewModel: Failed to load credits - \(error.localizedDescription)")
        } catch {
            errorMessage = "Failed to load credit balance"
            print("❌ CreditsViewModel: Unexpected error loading credits - \(error)")
        }

        isLoading = false
    }

    /// Load subscription details from server
    func loadSubscription() async {
        print("📋 CreditsViewModel: Loading subscription...")

        isLoading = true
        clearError()

        do {
            subscription = try await subscriptionService.fetchSubscription()

            if let sub = subscription {
                print("✅ CreditsViewModel: Subscription loaded - \(sub.plan.displayName) (\(sub.status.displayName))")
            } else {
                print("ℹ️ CreditsViewModel: No active subscription")
            }
        } catch let error as SubscriptionError {
            handleError(error)
            print("❌ CreditsViewModel: Failed to load subscription - \(error.localizedDescription)")
        } catch {
            errorMessage = "Failed to load subscription details"
            print("❌ CreditsViewModel: Unexpected error loading subscription - \(error)")
        }

        isLoading = false
    }

    /// Load transaction history
    /// - Parameter refresh: If true, reset pagination and reload from start
    func loadTransactions(refresh: Bool = false) async {
        if refresh {
            currentPage = 1
            transactions = []
            hasMoreTransactions = true
        }

        guard hasMoreTransactions else {
            print("ℹ️ CreditsViewModel: No more transactions to load")
            return
        }

        print("📜 CreditsViewModel: Loading transactions (page \(currentPage))...")

        isLoadingTransactions = true
        clearError()

        do {
            let newTransactions = try await subscriptionService.fetchTransactionHistory(
                page: currentPage,
                limit: transactionsPerPage
            )

            if refresh {
                transactions = newTransactions
            } else {
                transactions.append(contentsOf: newTransactions)
            }

            hasMoreTransactions = newTransactions.count == transactionsPerPage
            currentPage += 1

            print("✅ CreditsViewModel: Loaded \(newTransactions.count) transactions (total: \(transactions.count))")
        } catch let error as SubscriptionError {
            handleError(error)
            print("❌ CreditsViewModel: Failed to load transactions - \(error.localizedDescription)")
        } catch {
            errorMessage = "Failed to load transaction history"
            print("❌ CreditsViewModel: Unexpected error loading transactions - \(error)")
        }

        isLoadingTransactions = false
    }

    /// Refresh all data (credits, subscription, and transactions)
    func refreshAll() async {
        print("🔄 CreditsViewModel: Refreshing all data...")

        isLoading = true
        clearError()

        // Load credits and subscription in parallel
        async let creditsTask = subscriptionService.fetchCredits()
        async let subscriptionTask = subscriptionService.fetchSubscription()

        do {
            credits = try await creditsTask
            subscription = try await subscriptionTask

            print("✅ CreditsViewModel: All data refreshed successfully")
        } catch let error as SubscriptionError {
            handleError(error)
            print("❌ CreditsViewModel: Failed to refresh data - \(error.localizedDescription)")
        } catch {
            errorMessage = "Failed to refresh data"
            print("❌ CreditsViewModel: Unexpected error refreshing data - \(error)")
        }

        isLoading = false

        // Load transactions in background
        Task {
            await loadTransactions(refresh: true)
        }
    }

    // MARK: - Credit Purchases

    /// Purchase credits
    /// - Parameter amount: Number of credits to purchase
    func purchaseCredits(amount: Int) async {
        guard amount > 0 else {
            errorMessage = "Invalid credit amount"
            return
        }

        print("💰 CreditsViewModel: Purchasing \(amount) credits...")

        isPurchasing = true
        clearError()

        do {
            let checkoutURL = try await subscriptionService.purchaseCredits(amount: amount)

            // Open checkout URL in Safari
            if let url = URL(string: checkoutURL) {
                await openURL(url)
                successMessage = "Opening checkout..."
                print("✅ CreditsViewModel: Opening checkout URL")
            } else {
                throw SubscriptionError.checkoutFailed
            }
        } catch let error as SubscriptionError {
            handleError(error)
            print("❌ CreditsViewModel: Failed to purchase credits - \(error.localizedDescription)")
        } catch {
            errorMessage = "Failed to initiate credit purchase"
            print("❌ CreditsViewModel: Unexpected error purchasing credits - \(error)")
        }

        isPurchasing = false
    }

    // MARK: - Subscription Management

    /// Upgrade to Pro plan
    func upgradeToPro() async {
        await upgradeToSubscription(plan: .pro)
    }

    /// Upgrade to Yearly plan
    func upgradeToYearly() async {
        await upgradeToSubscription(plan: .yearly)
    }

    /// Upgrade to specified subscription plan
    /// - Parameter plan: Subscription plan to upgrade to
    func upgradeToSubscription(plan: SubscriptionPlan) async {
        guard plan != .free else {
            errorMessage = "Cannot upgrade to free plan"
            return
        }

        print("⭐ CreditsViewModel: Upgrading to \(plan.displayName)...")

        isLoading = true
        clearError()

        do {
            let checkoutURL = try await subscriptionService.createCheckoutSession(plan: plan)

            // Open checkout URL in Safari
            if let url = URL(string: checkoutURL) {
                await openURL(url)
                successMessage = "Opening checkout..."
                print("✅ CreditsViewModel: Opening checkout URL for \(plan.displayName)")
            } else {
                throw SubscriptionError.checkoutFailed
            }
        } catch let error as SubscriptionError {
            handleError(error)
            print("❌ CreditsViewModel: Failed to upgrade - \(error.localizedDescription)")
        } catch {
            errorMessage = "Failed to initiate subscription upgrade"
            print("❌ CreditsViewModel: Unexpected error upgrading - \(error)")
        }

        isLoading = false
    }

    /// Cancel active subscription
    func cancelSubscription() async {
        guard subscription?.isActive == true else {
            errorMessage = "No active subscription to cancel"
            return
        }

        print("🚫 CreditsViewModel: Cancelling subscription...")

        isCancelling = true
        clearError()

        do {
            try await subscriptionService.cancelSubscription()
            successMessage = "Subscription will cancel at period end"
            print("✅ CreditsViewModel: Subscription cancelled successfully")

            // Refresh subscription data
            await loadSubscription()
        } catch let error as SubscriptionError {
            handleError(error)
            print("❌ CreditsViewModel: Failed to cancel subscription - \(error.localizedDescription)")
        } catch {
            errorMessage = "Failed to cancel subscription"
            print("❌ CreditsViewModel: Unexpected error cancelling - \(error)")
        }

        isCancelling = false
    }

    /// Reactivate cancelled subscription
    func reactivateSubscription() async {
        guard subscription?.cancelAtPeriodEnd == true else {
            errorMessage = "Subscription is not scheduled for cancellation"
            return
        }

        print("♻️ CreditsViewModel: Reactivating subscription...")

        isLoading = true
        clearError()

        do {
            try await subscriptionService.reactivateSubscription()
            successMessage = "Subscription reactivated successfully"
            print("✅ CreditsViewModel: Subscription reactivated")

            // Refresh subscription data
            await loadSubscription()
        } catch let error as SubscriptionError {
            handleError(error)
            print("❌ CreditsViewModel: Failed to reactivate - \(error.localizedDescription)")
        } catch {
            errorMessage = "Failed to reactivate subscription"
            print("❌ CreditsViewModel: Unexpected error reactivating - \(error)")
        }

        isLoading = false
    }

    /// Open billing portal for subscription management
    func openBillingPortal() async {
        print("🏦 CreditsViewModel: Opening billing portal...")

        isLoading = true
        clearError()

        do {
            let portalURL = try await subscriptionService.getBillingPortalURL()

            if let url = URL(string: portalURL) {
                await openURL(url)
                print("✅ CreditsViewModel: Opening billing portal")
            } else {
                throw SubscriptionError.serverError("Invalid billing portal URL")
            }
        } catch let error as SubscriptionError {
            handleError(error)
            print("❌ CreditsViewModel: Failed to open billing portal - \(error.localizedDescription)")
        } catch {
            errorMessage = "Failed to open billing portal"
            print("❌ CreditsViewModel: Unexpected error opening portal - \(error)")
        }

        isLoading = false
    }

    // MARK: - Helper Methods

    /// Check if user has enough credits
    /// - Parameter amount: Number of credits needed
    /// - Returns: True if user has sufficient credits
    func hasCredits(_ amount: Int = 1) -> Bool {
        return credits?.hasCredits(amount) ?? false
    }

    /// Check if user is on a paid plan
    var isPaidPlan: Bool {
        return credits?.isPaidPlan ?? false
    }

    /// Check if user has active subscription
    var hasActiveSubscription: Bool {
        return subscription?.isActive ?? false
    }

    /// Get current plan display name
    var currentPlanName: String {
        return credits?.plan.displayName ?? "Free"
    }

    /// Calculate credit usage percentage
    var usagePercentage: Double {
        return credits?.usagePercentage ?? 0.0
    }

    // MARK: - Error Handling

    /// Handle SubscriptionError and set error message
    private func handleError(_ error: SubscriptionError) {
        errorMessage = error.localizedDescription
        os_log("❌ Error: %{public}@", log: logger, type: .error, error.localizedDescription)
    }

    /// Clear error and success messages
    func clearError() {
        errorMessage = nil
        successMessage = nil
    }

    /// Clear success message only
    func clearSuccess() {
        successMessage = nil
    }

    // MARK: - URL Handling

    /// Open URL in Safari or external browser
    /// - Parameter url: URL to open
    private func openURL(_ url: URL) async {
        #if os(iOS)
        await MainActor.run {
            UIApplication.shared.open(url)
        }
        #elseif os(macOS)
        await MainActor.run {
            NSWorkspace.shared.open(url)
        }
        #endif
    }

    // MARK: - Webhook/Payment Callbacks

    /// Handle successful payment callback
    /// This should be called when returning from Stripe checkout
    func handlePaymentSuccess() async {
        print("✅ CreditsViewModel: Payment successful, refreshing data...")
        successMessage = "Payment successful!"

        // Refresh all data to get updated credits/subscription
        await refreshAll()
    }

    /// Handle cancelled payment callback
    func handlePaymentCancelled() {
        print("⚠️ CreditsViewModel: Payment cancelled by user")
        errorMessage = "Payment was cancelled"
    }
}

// MARK: - Computed Properties

extension CreditsViewModel {
    /// Format total credits for display
    var totalCreditsDisplay: String {
        guard let credits = credits else { return "0" }
        return "\(credits.totalCredits)"
    }

    /// Format subscription credits for display
    var subscriptionCreditsDisplay: String {
        guard let credits = credits else { return "0" }
        return "\(credits.subscriptionCredits)"
    }

    /// Format purchased credits for display
    var purchasedCreditsDisplay: String {
        guard let credits = credits else { return "0" }
        return "\(credits.purchasedCredits)"
    }

    /// Format promotional credits for display
    var promotionalCreditsDisplay: String {
        guard let credits = credits else { return "0" }
        return "\(credits.promotionalCredits)"
    }

    /// Days until next credit reset
    var daysUntilReset: String {
        guard let days = credits?.daysUntilReset else {
            return "N/A"
        }

        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else {
            return "\(days) days"
        }
    }

    /// Subscription renewal message
    var renewalMessage: String? {
        return subscription?.renewalMessage
    }

    /// Check if subscription is set to cancel
    var isSubscriptionCancelling: Bool {
        return subscription?.cancelAtPeriodEnd ?? false
    }

    /// Days remaining in subscription period
    var subscriptionDaysRemaining: Int {
        return subscription?.daysRemaining ?? 0
    }
}

// MARK: - Mock Support

#if DEBUG
extension CreditsViewModel {
    /// Create mock view model for previews
    /// - Parameters:
    ///   - credits: Mock credit balance
    ///   - subscription: Mock subscription
    ///   - transactions: Mock transactions
    /// - Returns: Configured CreditsViewModel
    static func mock(
        credits: CreditBalance = .mock,
        subscription: Subscription? = .mock,
        transactions: [CreditTransaction] = CreditTransaction.mockAll
    ) -> CreditsViewModel {
        let viewModel = CreditsViewModel()
        viewModel.credits = credits
        viewModel.subscription = subscription
        viewModel.transactions = transactions
        viewModel.hasMoreTransactions = false
        return viewModel
    }

    /// Create mock view model with loading state
    static func mockLoading() -> CreditsViewModel {
        let viewModel = CreditsViewModel()
        viewModel.isLoading = true
        return viewModel
    }

    /// Create mock view model with error
    static func mockWithError(_ error: String = "Failed to load data") -> CreditsViewModel {
        let viewModel = CreditsViewModel()
        viewModel.errorMessage = error
        return viewModel
    }

    /// Create mock view model with free plan
    static func mockFree() -> CreditsViewModel {
        let viewModel = CreditsViewModel()
        viewModel.credits = .mockFree
        viewModel.subscription = nil
        return viewModel
    }

    /// Create mock view model with cancelled subscription
    static func mockCancelled() -> CreditsViewModel {
        let viewModel = CreditsViewModel()
        viewModel.credits = .mock
        viewModel.subscription = .mockCancelled
        return viewModel
    }

    /// Create mock view model with empty credits
    static func mockEmpty() -> CreditsViewModel {
        let viewModel = CreditsViewModel()
        viewModel.credits = .mockEmpty
        viewModel.subscription = nil
        viewModel.transactions = []
        return viewModel
    }
}
#endif
