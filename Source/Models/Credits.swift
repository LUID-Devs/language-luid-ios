//
//  Credits.swift
//  LanguageLuid
//
//  Credit and subscription models for language learning platform
//  Supports multiple credit types: subscription, purchased, and promotional
//

import Foundation

// MARK: - Subscription Plan

/// Subscription plan tiers
enum SubscriptionPlan: String, Codable, CaseIterable {
    case free = "free"
    case pro = "pro"
    case yearly = "yearly"

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .yearly: return "Yearly"
        }
    }

    var description: String {
        switch self {
        case .free:
            return "Basic access with limited credits"
        case .pro:
            return "Monthly subscription with unlimited lessons"
        case .yearly:
            return "Annual subscription with best value"
        }
    }

    var monthlyCredits: Int {
        switch self {
        case .free: return 10
        case .pro: return 1000
        case .yearly: return 1200
        }
    }

    var price: String {
        switch self {
        case .free: return "$0"
        case .pro: return "$9.99"
        case .yearly: return "$99.99"
        }
    }

    var priceValue: Double {
        switch self {
        case .free: return 0.0
        case .pro: return 9.99
        case .yearly: return 99.99
        }
    }
}

// MARK: - Subscription Status

/// Current status of a subscription
enum SubscriptionStatus: String, Codable {
    case active = "active"
    case cancelled = "cancelled"
    case pastDue = "past_due"
    case trialing = "trialing"
    case incomplete = "incomplete"
    case incompleteExpired = "incomplete_expired"
    case unpaid = "unpaid"

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .cancelled: return "Cancelled"
        case .pastDue: return "Past Due"
        case .trialing: return "Trial"
        case .incomplete: return "Incomplete"
        case .incompleteExpired: return "Expired"
        case .unpaid: return "Unpaid"
        }
    }

    var isActive: Bool {
        return self == .active || self == .trialing
    }

    var requiresAction: Bool {
        return self == .pastDue || self == .incomplete || self == .unpaid
    }
}

// MARK: - Credit Balance

/// User's current credit balance across all types
struct CreditBalance: Codable, Equatable {
    let totalCredits: Int
    let subscriptionCredits: Int
    let purchasedCredits: Int
    let promotionalCredits: Int
    let plan: SubscriptionPlan
    let nextReset: Date?

    // Note: No CodingKeys needed - APIClient uses .convertFromSnakeCase decoder strategy

    /// Calculate days until next credit reset
    var daysUntilReset: Int? {
        guard let resetDate = nextReset else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: resetDate)
        return components.day
    }

    /// Format reset date for display
    var resetDateDisplay: String? {
        guard let resetDate = nextReset else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: resetDate)
    }

    /// Check if user has enough credits
    func hasCredits(_ amount: Int = 1) -> Bool {
        return totalCredits >= amount
    }

    /// Check if user is on a paid plan
    var isPaidPlan: Bool {
        return plan != .free
    }

    /// Percentage of subscription credits used (0.0 to 1.0)
    var usagePercentage: Double {
        guard plan.monthlyCredits > 0 else { return 0.0 }
        let used = plan.monthlyCredits - subscriptionCredits
        return Double(used) / Double(plan.monthlyCredits)
    }
}

// MARK: - Subscription

/// User's subscription details
struct Subscription: Codable, Identifiable, Equatable {
    let id: String
    let userId: String
    let plan: SubscriptionPlan
    let status: SubscriptionStatus
    let currentPeriodStart: Date
    let currentPeriodEnd: Date
    let cancelAtPeriodEnd: Bool
    let cancelledAt: Date?
    let trialEnd: Date?
    let createdAt: Date
    let updatedAt: Date

    // Note: No CodingKeys needed - APIClient uses .convertFromSnakeCase decoder strategy

    /// Check if subscription is currently active
    var isActive: Bool {
        return status.isActive && Date() < currentPeriodEnd
    }

    /// Check if subscription is in trial period
    var isTrialing: Bool {
        guard let trialEnd = trialEnd else { return false }
        return status == .trialing && Date() < trialEnd
    }

    /// Days remaining in current period
    var daysRemaining: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: currentPeriodEnd)
        return max(components.day ?? 0, 0)
    }

    /// Format period end date for display
    var periodEndDisplay: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: currentPeriodEnd)
    }

    /// Renewal or cancellation message
    var renewalMessage: String {
        if cancelAtPeriodEnd {
            return "Subscription will cancel on \(periodEndDisplay)"
        } else if isActive {
            return "Renews on \(periodEndDisplay)"
        } else {
            return "Expired on \(periodEndDisplay)"
        }
    }
}

// MARK: - Credit Transaction

/// Transaction type for credit history
enum CreditTransactionType: String, Codable {
    case purchase = "purchase"
    case subscription = "subscription"
    case promotional = "promotional"
    case usage = "usage"
    case refund = "refund"
    case bonus = "bonus"
    case reset = "reset"

    var displayName: String {
        switch self {
        case .purchase: return "Purchase"
        case .subscription: return "Subscription"
        case .promotional: return "Promotional"
        case .usage: return "Usage"
        case .refund: return "Refund"
        case .bonus: return "Bonus"
        case .reset: return "Reset"
        }
    }

    var icon: String {
        switch self {
        case .purchase: return "cart.fill"
        case .subscription: return "star.fill"
        case .promotional: return "gift.fill"
        case .usage: return "minus.circle.fill"
        case .refund: return "arrow.uturn.backward.circle.fill"
        case .bonus: return "sparkles"
        case .reset: return "arrow.clockwise.circle.fill"
        }
    }

    var isDebit: Bool {
        return self == .usage
    }
}

/// Credit transaction history entry
struct CreditTransaction: Codable, Identifiable, Equatable {
    let id: String
    let userId: String
    let type: CreditTransactionType
    let amount: Int
    let balanceBefore: Int
    let balanceAfter: Int
    let description: String
    let metadata: [String: String]?
    let createdAt: Date

    // Note: No CodingKeys needed - APIClient uses .convertFromSnakeCase decoder strategy

    /// Format amount with +/- prefix
    var formattedAmount: String {
        let prefix = type.isDebit ? "-" : "+"
        return "\(prefix)\(abs(amount))"
    }

    /// Format creation date for display
    var dateDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    /// Full date display
    var fullDateDisplay: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

// MARK: - API Response Models

/// Response from fetching credit balance
struct CreditBalanceResponse: Codable {
    let success: Bool
    let data: CreditBalance
}

/// Response from fetching subscription
struct SubscriptionResponse: Codable {
    let success: Bool
    let data: Subscription?
}

/// Response from creating checkout session
struct CheckoutSessionResponse: Codable {
    let success: Bool
    let url: String
    let sessionId: String?
}

/// Response from fetching transaction history
struct TransactionHistoryResponse: Codable {
    let success: Bool
    let data: [CreditTransaction]
    let pagination: PaginationInfo?
}

/// Pagination information for transaction history
struct PaginationInfo: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
}

// MARK: - Mock Data

#if DEBUG
extension CreditBalance {
    static let mock = CreditBalance(
        totalCredits: 850,
        subscriptionCredits: 750,
        purchasedCredits: 50,
        promotionalCredits: 50,
        plan: .pro,
        nextReset: Calendar.current.date(byAdding: .day, value: 15, to: Date())
    )

    static let mockFree = CreditBalance(
        totalCredits: 5,
        subscriptionCredits: 5,
        purchasedCredits: 0,
        promotionalCredits: 0,
        plan: .free,
        nextReset: Calendar.current.date(byAdding: .day, value: 7, to: Date())
    )

    static let mockEmpty = CreditBalance(
        totalCredits: 0,
        subscriptionCredits: 0,
        purchasedCredits: 0,
        promotionalCredits: 0,
        plan: .free,
        nextReset: nil
    )
}

extension Subscription {
    static let mock = Subscription(
        id: UUID().uuidString,
        userId: UUID().uuidString,
        plan: .pro,
        status: .active,
        currentPeriodStart: Calendar.current.date(byAdding: .day, value: -15, to: Date())!,
        currentPeriodEnd: Calendar.current.date(byAdding: .day, value: 15, to: Date())!,
        cancelAtPeriodEnd: false,
        cancelledAt: nil,
        trialEnd: nil,
        createdAt: Calendar.current.date(byAdding: .month, value: -3, to: Date())!,
        updatedAt: Date()
    )

    static let mockCancelled = Subscription(
        id: UUID().uuidString,
        userId: UUID().uuidString,
        plan: .pro,
        status: .active,
        currentPeriodStart: Calendar.current.date(byAdding: .day, value: -15, to: Date())!,
        currentPeriodEnd: Calendar.current.date(byAdding: .day, value: 15, to: Date())!,
        cancelAtPeriodEnd: true,
        cancelledAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
        trialEnd: nil,
        createdAt: Calendar.current.date(byAdding: .month, value: -3, to: Date())!,
        updatedAt: Date()
    )
}

extension CreditTransaction {
    static let mock = CreditTransaction(
        id: UUID().uuidString,
        userId: UUID().uuidString,
        type: .subscription,
        amount: 1000,
        balanceBefore: 50,
        balanceAfter: 1050,
        description: "Monthly subscription credits",
        metadata: nil,
        createdAt: Date()
    )

    static let mockUsage = CreditTransaction(
        id: UUID().uuidString,
        userId: UUID().uuidString,
        type: .usage,
        amount: -5,
        balanceBefore: 1050,
        balanceAfter: 1045,
        description: "Completed lesson: Spanish Basics",
        metadata: ["lesson_id": "123"],
        createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!
    )

    static let mockPurchase = CreditTransaction(
        id: UUID().uuidString,
        userId: UUID().uuidString,
        type: .purchase,
        amount: 100,
        balanceBefore: 1045,
        balanceAfter: 1145,
        description: "Purchased 100 credits",
        metadata: ["amount": "9.99", "currency": "USD"],
        createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    )

    static let mockPromo = CreditTransaction(
        id: UUID().uuidString,
        userId: UUID().uuidString,
        type: .promotional,
        amount: 50,
        balanceBefore: 1145,
        balanceAfter: 1195,
        description: "Welcome bonus",
        metadata: ["promo_code": "WELCOME50"],
        createdAt: Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    )

    static let mockAll: [CreditTransaction] = [
        mock, mockUsage, mockPurchase, mockPromo
    ]
}
#endif
