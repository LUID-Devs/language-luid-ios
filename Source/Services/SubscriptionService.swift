//
//  SubscriptionService.swift
//  LanguageLuid
//
//  Service for managing credits, subscriptions, and billing
//  Integrates with backend subscription API endpoints
//

import Foundation
import os.log

/// Subscription service errors
enum SubscriptionError: Error {
    case notAuthenticated
    case invalidResponse
    case networkError(Error)
    case serverError(String)
    case checkoutFailed
    case cancellationFailed
    case noPurchaseHistory

    var localizedDescription: String {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to access subscription features"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let message):
            return message
        case .checkoutFailed:
            return "Failed to create checkout session"
        case .cancellationFailed:
            return "Failed to cancel subscription"
        case .noPurchaseHistory:
            return "No purchase history available"
        }
    }
}

/// Subscription service for credit and subscription management
@MainActor
class SubscriptionService {

    // MARK: - Singleton

    static let shared = SubscriptionService()

    // MARK: - Dependencies

    private let apiClient: APIClient
    private let logger = OSLog(subsystem: "com.luid.languageluid", category: "SubscriptionService")

    // MARK: - Initialization

    private init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    // MARK: - Credit Balance

    /// Fetch current credit balance
    /// - Returns: Current credit balance including all credit types
    /// - Throws: SubscriptionError if request fails
    func fetchCredits() async throws -> CreditBalance {
        NSLog("💳 SubscriptionService: Fetching credit balance...")
        os_log("💳 Fetching credit balance", log: logger, type: .info)

        do {
            // Check for custom endpoint or use default
            let endpoint = "/users/credits" // Backend endpoint for credits
            let response: CreditBalanceResponse = try await apiClient.get(
                endpoint,
                requiresAuth: true
            )

            guard response.success else {
                throw SubscriptionError.invalidResponse
            }

            NSLog("✅ SubscriptionService: Credit balance fetched - \(response.data.totalCredits) total credits")
            os_log("✅ Credit balance: %{public}d credits", log: logger, type: .info, response.data.totalCredits)

            return response.data

        } catch let error as APIError {
            NSLog("❌ SubscriptionService: Failed to fetch credits - \(error.localizedDescription)")
            os_log("❌ Failed to fetch credits: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw mapAPIError(error)
        } catch {
            NSLog("❌ SubscriptionService: Unexpected error fetching credits - \(error)")
            os_log("❌ Unexpected error: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw SubscriptionError.networkError(error)
        }
    }

    // MARK: - Subscription Management

    /// Fetch current subscription details
    /// - Returns: Current subscription if exists, nil if no active subscription
    /// - Throws: SubscriptionError if request fails
    func fetchSubscription() async throws -> Subscription? {
        NSLog("📋 SubscriptionService: Fetching subscription...")
        os_log("📋 Fetching subscription", log: logger, type: .info)

        do {
            let response: SubscriptionResponse = try await apiClient.get(
                APIEndpoint.mySubscription,
                requiresAuth: true
            )

            guard response.success else {
                throw SubscriptionError.invalidResponse
            }

            if let subscription = response.data {
                NSLog("✅ SubscriptionService: Subscription fetched - \(subscription.plan.displayName) (\(subscription.status.displayName))")
                os_log("✅ Subscription: %{public}@ - %{public}@",
                       log: logger, type: .info,
                       subscription.plan.displayName,
                       subscription.status.displayName)
            } else {
                NSLog("ℹ️ SubscriptionService: No active subscription")
                os_log("ℹ️ No active subscription", log: logger, type: .info)
            }

            return response.data

        } catch let error as APIError {
            NSLog("❌ SubscriptionService: Failed to fetch subscription - \(error.localizedDescription)")
            os_log("❌ Failed to fetch subscription: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw mapAPIError(error)
        } catch {
            NSLog("❌ SubscriptionService: Unexpected error fetching subscription - \(error)")
            os_log("❌ Unexpected error: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw SubscriptionError.networkError(error)
        }
    }

    /// Create checkout session for subscription purchase
    /// - Parameter plan: Subscription plan to purchase
    /// - Returns: Checkout URL to open in browser
    /// - Throws: SubscriptionError if request fails
    func createCheckoutSession(plan: SubscriptionPlan) async throws -> String {
        NSLog("💰 SubscriptionService: Creating checkout session for \(plan.displayName)...")
        os_log("💰 Creating checkout for: %{public}@", log: logger, type: .info, plan.displayName)

        do {
            let parameters: [String: Any] = [
                "plan": plan.rawValue,
                "success_url": "languageluid://subscription/success",
                "cancel_url": "languageluid://subscription/cancel"
            ]

            let response: CheckoutSessionResponse = try await apiClient.post(
                APIEndpoint.createCheckoutSession,
                parameters: parameters,
                requiresAuth: true
            )

            guard response.success, !response.url.isEmpty else {
                throw SubscriptionError.checkoutFailed
            }

            NSLog("✅ SubscriptionService: Checkout session created")
            os_log("✅ Checkout session created", log: logger, type: .info)

            return response.url

        } catch let error as APIError {
            NSLog("❌ SubscriptionService: Failed to create checkout session - \(error.localizedDescription)")
            os_log("❌ Failed to create checkout: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw mapAPIError(error)
        } catch {
            NSLog("❌ SubscriptionService: Unexpected error creating checkout - \(error)")
            os_log("❌ Unexpected error: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw SubscriptionError.networkError(error)
        }
    }

    /// Cancel active subscription (will remain active until period end)
    /// - Throws: SubscriptionError if request fails
    func cancelSubscription() async throws {
        NSLog("🚫 SubscriptionService: Cancelling subscription...")
        os_log("🚫 Cancelling subscription", log: logger, type: .info)

        do {
            struct CancelResponse: Codable {
                let success: Bool
                let message: String?
            }

            let response: CancelResponse = try await apiClient.post(
                APIEndpoint.cancelSubscription,
                requiresAuth: true
            )

            guard response.success else {
                throw SubscriptionError.cancellationFailed
            }

            NSLog("✅ SubscriptionService: Subscription cancelled successfully")
            os_log("✅ Subscription cancelled", log: logger, type: .info)

        } catch let error as APIError {
            NSLog("❌ SubscriptionService: Failed to cancel subscription - \(error.localizedDescription)")
            os_log("❌ Failed to cancel: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw mapAPIError(error)
        } catch {
            NSLog("❌ SubscriptionService: Unexpected error cancelling subscription - \(error)")
            os_log("❌ Unexpected error: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw SubscriptionError.networkError(error)
        }
    }

    /// Reactivate a cancelled subscription
    /// - Throws: SubscriptionError if request fails
    func reactivateSubscription() async throws {
        NSLog("♻️ SubscriptionService: Reactivating subscription...")
        os_log("♻️ Reactivating subscription", log: logger, type: .info)

        do {
            struct ReactivateResponse: Codable {
                let success: Bool
                let message: String?
            }

            let response: ReactivateResponse = try await apiClient.post(
                "/subscriptions/reactivate",
                requiresAuth: true
            )

            guard response.success else {
                throw SubscriptionError.serverError("Failed to reactivate subscription")
            }

            NSLog("✅ SubscriptionService: Subscription reactivated successfully")
            os_log("✅ Subscription reactivated", log: logger, type: .info)

        } catch let error as APIError {
            NSLog("❌ SubscriptionService: Failed to reactivate subscription - \(error.localizedDescription)")
            os_log("❌ Failed to reactivate: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw mapAPIError(error)
        } catch {
            NSLog("❌ SubscriptionService: Unexpected error reactivating subscription - \(error)")
            os_log("❌ Unexpected error: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw SubscriptionError.networkError(error)
        }
    }

    /// Open billing portal for subscription management
    /// - Returns: Billing portal URL to open in browser
    /// - Throws: SubscriptionError if request fails
    func getBillingPortalURL() async throws -> String {
        NSLog("🏦 SubscriptionService: Getting billing portal URL...")
        os_log("🏦 Getting billing portal", log: logger, type: .info)

        do {
            struct PortalResponse: Codable {
                let success: Bool
                let url: String
            }

            let parameters: [String: Any] = [
                "return_url": "languageluid://subscription/billing"
            ]

            let response: PortalResponse = try await apiClient.post(
                APIEndpoint.billingPortal,
                parameters: parameters,
                requiresAuth: true
            )

            guard response.success, !response.url.isEmpty else {
                throw SubscriptionError.serverError("Failed to get billing portal URL")
            }

            NSLog("✅ SubscriptionService: Billing portal URL retrieved")
            os_log("✅ Billing portal URL retrieved", log: logger, type: .info)

            return response.url

        } catch let error as APIError {
            NSLog("❌ SubscriptionService: Failed to get billing portal - \(error.localizedDescription)")
            os_log("❌ Failed to get billing portal: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw mapAPIError(error)
        } catch {
            NSLog("❌ SubscriptionService: Unexpected error getting billing portal - \(error)")
            os_log("❌ Unexpected error: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw SubscriptionError.networkError(error)
        }
    }

    // MARK: - Transaction History

    /// Fetch credit transaction history
    /// - Parameters:
    ///   - page: Page number for pagination (default: 1)
    ///   - limit: Number of transactions per page (default: 50)
    /// - Returns: Array of credit transactions
    /// - Throws: SubscriptionError if request fails
    func fetchTransactionHistory(page: Int = 1, limit: Int = 50) async throws -> [CreditTransaction] {
        NSLog("📜 SubscriptionService: Fetching transaction history (page: \(page), limit: \(limit))...")
        os_log("📜 Fetching transactions: page %{public}d", log: logger, type: .info, page)

        do {
            let endpoint = "/users/credits/transactions"
            let parameters: [String: Any] = [
                "page": page,
                "limit": limit
            ]

            let response: TransactionHistoryResponse = try await apiClient.get(
                endpoint,
                parameters: parameters,
                requiresAuth: true
            )

            guard response.success else {
                throw SubscriptionError.invalidResponse
            }

            NSLog("✅ SubscriptionService: Fetched \(response.data.count) transactions")
            os_log("✅ Fetched %{public}d transactions", log: logger, type: .info, response.data.count)

            return response.data

        } catch let error as APIError {
            NSLog("❌ SubscriptionService: Failed to fetch transactions - \(error.localizedDescription)")
            os_log("❌ Failed to fetch transactions: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw mapAPIError(error)
        } catch {
            NSLog("❌ SubscriptionService: Unexpected error fetching transactions - \(error)")
            os_log("❌ Unexpected error: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw SubscriptionError.networkError(error)
        }
    }

    // MARK: - Credit Purchases

    /// Purchase additional credits
    /// - Parameters:
    ///   - amount: Number of credits to purchase
    ///   - paymentMethodId: Payment method ID from Stripe (optional)
    /// - Returns: Checkout URL if payment method not provided, or success if payment completed
    /// - Throws: SubscriptionError if request fails
    func purchaseCredits(amount: Int, paymentMethodId: String? = nil) async throws -> String {
        NSLog("💳 SubscriptionService: Purchasing \(amount) credits...")
        os_log("💳 Purchasing %{public}d credits", log: logger, type: .info, amount)

        do {
            var parameters: [String: Any] = [
                "amount": amount,
                "success_url": "languageluid://credits/purchase/success",
                "cancel_url": "languageluid://credits/purchase/cancel"
            ]

            if let paymentMethodId = paymentMethodId {
                parameters["payment_method_id"] = paymentMethodId
            }

            let response: CheckoutSessionResponse = try await apiClient.post(
                "/users/credits/purchase",
                parameters: parameters,
                requiresAuth: true
            )

            guard response.success, !response.url.isEmpty else {
                throw SubscriptionError.serverError("Failed to create purchase session")
            }

            NSLog("✅ SubscriptionService: Credit purchase session created")
            os_log("✅ Purchase session created", log: logger, type: .info)

            return response.url

        } catch let error as APIError {
            NSLog("❌ SubscriptionService: Failed to purchase credits - \(error.localizedDescription)")
            os_log("❌ Failed to purchase: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw mapAPIError(error)
        } catch {
            NSLog("❌ SubscriptionService: Unexpected error purchasing credits - \(error)")
            os_log("❌ Unexpected error: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw SubscriptionError.networkError(error)
        }
    }

    // MARK: - Subscription Plans

    /// Fetch available subscription plans
    /// - Returns: Array of available subscription plans with pricing
    /// - Throws: SubscriptionError if request fails
    func fetchSubscriptionPlans() async throws -> [SubscriptionPlanDetails] {
        NSLog("📋 SubscriptionService: Fetching subscription plans...")
        os_log("📋 Fetching plans", log: logger, type: .info)

        do {
            struct PlansResponse: Codable {
                let success: Bool
                let data: [SubscriptionPlanDetails]
            }

            let response: PlansResponse = try await apiClient.get(
                APIEndpoint.subscriptionPlans,
                requiresAuth: false
            )

            guard response.success else {
                throw SubscriptionError.invalidResponse
            }

            NSLog("✅ SubscriptionService: Fetched \(response.data.count) plans")
            os_log("✅ Fetched %{public}d plans", log: logger, type: .info, response.data.count)

            return response.data

        } catch let error as APIError {
            NSLog("❌ SubscriptionService: Failed to fetch plans - \(error.localizedDescription)")
            os_log("❌ Failed to fetch plans: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw mapAPIError(error)
        } catch {
            NSLog("❌ SubscriptionService: Unexpected error fetching plans - \(error)")
            os_log("❌ Unexpected error: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw SubscriptionError.networkError(error)
        }
    }

    // MARK: - Error Mapping

    /// Map APIError to SubscriptionError
    private func mapAPIError(_ error: APIError) -> SubscriptionError {
        switch error {
        case .unauthorized:
            return .notAuthenticated
        case .serverError(let message):
            return .serverError(message)
        case .networkError(let error):
            return .networkError(error)
        default:
            return .serverError(error.localizedDescription)
        }
    }
}

// MARK: - Supporting Models

/// Detailed subscription plan information from API
struct SubscriptionPlanDetails: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let currency: String
    let interval: String
    let credits: Int
    let features: [String]
    let isPopular: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, description, price, currency, interval, credits, features
        case isPopular = "is_popular"
    }

    var priceDisplay: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: price)) ?? "$\(price)"
    }
}
