//
//  RevenueCatConfig.swift
//  LanguageLuid
//
//  RevenueCat configuration and constants
//  Contains API keys and product identifiers for in-app purchases
//

import Foundation

/// RevenueCat configuration
enum RevenueCatConfig {
    // MARK: - API Keys

    /// RevenueCat API Key (placeholder for now)
    /// TODO: Replace with actual RevenueCat API key from dashboard
    static let apiKey = "appl_placeholder_key_for_testing"

    // MARK: - Product Identifiers

    /// Monthly subscription product ID
    static let monthlyProductId = "com.luid.languageluid.premium.monthly"

    /// Annual subscription product ID
    static let annualProductId = "com.luid.languageluid.premium.annual"

    /// Lifetime purchase product ID
    static let lifetimeProductId = "com.luid.languageluid.premium.lifetime"

    // MARK: - Entitlement Identifiers

    /// Premium entitlement identifier
    static let premiumEntitlementId = "premium"

    // MARK: - Free Tier

    /// Number of free lessons available without subscription
    static let freeLessonLimit = 3

    // MARK: - Environment

    /// Whether to use sandbox environment for testing
    static var useSandbox: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Subscription Plans (Placeholder Data)

/// Subscription plan details for display
struct PaywallPlan: Identifiable, Equatable {
    let id: String
    let name: String
    let price: String
    let duration: String
    let pricePerMonth: String?
    let savings: String?
    let isPopular: Bool
    let features: [String]

    static let free = PaywallPlan(
        id: "free",
        name: "Free",
        price: "$0",
        duration: "Forever",
        pricePerMonth: nil,
        savings: nil,
        isPopular: false,
        features: [
            "First 3 lessons",
            "Basic pronunciation practice",
            "Limited progress tracking"
        ]
    )

    static let monthly = PaywallPlan(
        id: RevenueCatConfig.monthlyProductId,
        name: "Monthly Premium",
        price: "$9.99",
        duration: "per month",
        pricePerMonth: "$9.99/month",
        savings: nil,
        isPopular: false,
        features: [
            "Unlock ALL lessons",
            "Advanced pronunciation AI",
            "Offline mode",
            "No ads",
            "Priority support",
            "Progress analytics",
            "Custom learning paths"
        ]
    )

    static let annual = PaywallPlan(
        id: RevenueCatConfig.annualProductId,
        name: "Annual Premium",
        price: "$79.99",
        duration: "per year",
        pricePerMonth: "$6.67/month",
        savings: "Save 33%",
        isPopular: true,
        features: [
            "Unlock ALL lessons",
            "Advanced pronunciation AI",
            "Offline mode",
            "No ads",
            "Priority support",
            "Progress analytics",
            "Custom learning paths",
            "Exclusive content"
        ]
    )

    static let allPlans: [PaywallPlan] = [free, monthly, annual]
    static let paidPlans: [PaywallPlan] = [monthly, annual]
}

/// Subscription status
enum RevenueCatStatus: String, Codable {
    case free
    case premium
    case trial
    case expired

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Premium"
        case .trial: return "Trial"
        case .expired: return "Expired"
        }
    }

    var isPremium: Bool {
        self == .premium || self == .trial
    }
}
