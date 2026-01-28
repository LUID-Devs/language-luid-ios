//
//  RevenueCatManager.swift
//  LanguageLuid
//
//  Mock RevenueCat service for managing subscriptions and in-app purchases
//  This is a placeholder implementation until RevenueCat SDK is fully integrated
//

import Foundation
import Combine
import os.log

/// RevenueCat Manager Errors
enum RevenueCatError: Error, LocalizedError {
    case notConfigured
    case purchaseFailed(String)
    case restoreFailed
    case noProductsAvailable
    case userCancelled

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "RevenueCat is not configured"
        case .purchaseFailed(let reason):
            return "Purchase failed: \(reason)"
        case .restoreFailed:
            return "Failed to restore purchases"
        case .noProductsAvailable:
            return "No subscription plans available"
        case .userCancelled:
            return "Purchase was cancelled"
        }
    }
}

/// Mock RevenueCat Manager for subscription management
/// TODO: Replace with actual RevenueCat SDK integration
@MainActor
class RevenueCatManager: ObservableObject {

    // MARK: - Singleton

    static let shared = RevenueCatManager()

    // MARK: - Published Properties

    /// Current subscription status
    @Published private(set) var subscriptionStatus: RevenueCatStatus = .free

    /// Available subscription plans
    @Published private(set) var availablePlans: [PaywallPlan] = []

    /// Whether user has active premium subscription
    @Published private(set) var isPremiumUser: Bool = false

    /// Current offering (placeholder)
    @Published private(set) var currentOffering: String? = nil

    /// Loading state
    @Published private(set) var isLoading: Bool = false

    // MARK: - Private Properties

    private let logger = OSLog(subsystem: "com.luid.languageluid", category: "RevenueCatManager")
    private let userDefaults = UserDefaults.standard
    private let subscriptionStatusKey = "user_subscription_status"
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        os_log("RevenueCatManager initialized (MOCK mode)", log: logger, type: .info)
        loadSubscriptionStatus()
        setupObservers()
    }

    // MARK: - Configuration

    /// Configure RevenueCat with API key
    /// TODO: Replace with actual RevenueCat configuration
    func configure() {
        os_log("Configuring RevenueCat with key: %{public}@", log: logger, type: .info, RevenueCatConfig.apiKey)

        // Mock configuration - in production, this would initialize RevenueCat SDK
        availablePlans = PaywallPlan.paidPlans

        os_log("✅ RevenueCat configured (MOCK)", log: logger, type: .info)
    }

    // MARK: - Subscription Status

    /// Load subscription status from UserDefaults
    private func loadSubscriptionStatus() {
        if let savedStatus = userDefaults.string(forKey: subscriptionStatusKey),
           let status = RevenueCatStatus(rawValue: savedStatus) {
            subscriptionStatus = status
            isPremiumUser = status.isPremium
            os_log("Loaded subscription status: %{public}@", log: logger, type: .info, status.displayName)
        } else {
            // Default to free
            subscriptionStatus = .free
            isPremiumUser = false
        }
    }

    /// Save subscription status to UserDefaults
    private func saveSubscriptionStatus() {
        userDefaults.set(subscriptionStatus.rawValue, forKey: subscriptionStatusKey)
        isPremiumUser = subscriptionStatus.isPremium
        os_log("Saved subscription status: %{public}@", log: logger, type: .info, subscriptionStatus.displayName)
    }

    // MARK: - Fetch Offerings

    /// Fetch available subscription offerings
    /// TODO: Replace with actual RevenueCat offerings fetch
    func fetchOfferings() async throws {
        os_log("Fetching subscription offerings...", log: logger, type: .info)

        isLoading = true

        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Mock offerings
        availablePlans = PaywallPlan.paidPlans
        currentOffering = "default"

        isLoading = false

        os_log("✅ Fetched %d subscription plans (MOCK)", log: logger, type: .info, availablePlans.count)
    }

    // MARK: - Purchase

    /// Purchase a subscription plan
    /// TODO: Replace with actual RevenueCat purchase flow
    func purchase(_ plan: PaywallPlan) async throws {
        os_log("Purchasing plan: %{public}@", log: logger, type: .info, plan.name)

        isLoading = true

        // Simulate purchase flow
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Mock success - grant premium access
        subscriptionStatus = .premium
        saveSubscriptionStatus()

        isLoading = false

        os_log("✅ Purchase successful (MOCK): %{public}@", log: logger, type: .info, plan.name)

        // Post notification for purchase success
        NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
    }

    /// Purchase by product ID
    func purchase(productId: String) async throws {
        guard let plan = availablePlans.first(where: { $0.id == productId }) else {
            throw RevenueCatError.noProductsAvailable
        }
        try await purchase(plan)
    }

    // MARK: - Restore Purchases

    /// Restore previous purchases
    /// TODO: Replace with actual RevenueCat restore
    func restorePurchases() async throws {
        os_log("Restoring purchases...", log: logger, type: .info)

        isLoading = true

        // Simulate restore delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Mock restore - check if user had previous subscription
        if subscriptionStatus == .premium || subscriptionStatus == .trial {
            os_log("✅ Purchases restored (MOCK) - Premium active", log: logger, type: .info)
        } else {
            os_log("ℹ️ No purchases to restore (MOCK)", log: logger, type: .info)
            throw RevenueCatError.restoreFailed
        }

        isLoading = false

        // Post notification
        NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
    }

    // MARK: - Access Control

    /// Check if a lesson is accessible based on subscription status
    func canAccessLesson(lessonNumber: Int) -> Bool {
        // Free users get first N lessons
        if lessonNumber <= RevenueCatConfig.freeLessonLimit {
            return true
        }

        // Premium users get everything
        return isPremiumUser
    }

    /// Check if user has premium access
    func hasPremiumAccess() -> Bool {
        return isPremiumUser
    }

    // MARK: - Testing/Debug Methods

    #if DEBUG
    /// Set subscription status for testing (debug only)
    func setSubscriptionStatus(_ status: RevenueCatStatus) {
        os_log("🧪 DEBUG: Setting subscription status to %{public}@", log: logger, type: .debug, status.displayName)
        subscriptionStatus = status
        saveSubscriptionStatus()
        NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
    }

    /// Grant premium access for testing (debug only)
    func grantPremiumForTesting() {
        setSubscriptionStatus(.premium)
    }

    /// Revoke premium access for testing (debug only)
    func revokePremiumForTesting() {
        setSubscriptionStatus(.free)
    }
    #endif

    // MARK: - Observers

    private func setupObservers() {
        // Subscribe to subscription status changes
        $subscriptionStatus
            .sink { [weak self] status in
                self?.isPremiumUser = status.isPremium
            }
            .store(in: &cancellables)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when subscription status changes
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
}
