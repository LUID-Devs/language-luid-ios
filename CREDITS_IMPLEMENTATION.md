# Credits & Subscription System Implementation

## Overview
Complete credits and subscription management system for Language Luid iOS app, following the architecture pattern from luidgpt-ios and language-luid-frontend.

## Files Created

### 1. Models/Credits.swift (486 lines)
**Location:** `/Users/alaindimabuyo/luid_projects/language-luid-ios/LanguageLuid/Models/Credits.swift`

**Key Components:**
- `SubscriptionPlan`: Enum for free, pro, yearly plans with pricing and credit allocations
- `SubscriptionStatus`: Active, cancelled, past_due, trialing, etc.
- `CreditBalance`: Total credits broken down by type (subscription, purchased, promotional)
- `Subscription`: Full subscription details with period management
- `CreditTransaction`: Transaction history with type, amount, and metadata
- API Response models with snake_case Codable conversion
- Comprehensive mock data for previews and testing

**Features:**
- Snake_case to camelCase automatic conversion
- Date formatting helpers
- Usage percentage calculations
- Days until reset/renewal
- Rich computed properties for UI display

### 2. Services/SubscriptionService.swift (471 lines)
**Location:** `/Users/alaindimabuyo/luid_projects/language-luid-ios/LanguageLuid/Services/SubscriptionService.swift`

**Key Components:**
- Singleton service pattern matching APIClient architecture
- `SubscriptionError`: Specialized error handling
- Integration with existing APIClient and APIEndpoint

**API Methods:**
```swift
// Credit Management
func fetchCredits() async throws -> CreditBalance
func fetchTransactionHistory(page: Int, limit: Int) async throws -> [CreditTransaction]

// Subscription Management
func fetchSubscription() async throws -> Subscription?
func createCheckoutSession(plan: SubscriptionPlan) async throws -> String
func cancelSubscription() async throws
func reactivateSubscription() async throws
func getBillingPortalURL() async throws -> String

// Purchases
func purchaseCredits(amount: Int, paymentMethodId: String?) async throws -> String
func fetchSubscriptionPlans() async throws -> [SubscriptionPlanDetails]
```

**Backend Integration:**
- Uses existing APIEndpoint enum for subscription routes
- Custom `/users/credits` and `/users/credits/transactions` endpoints
- Stripe checkout session URLs for payment flows
- Comprehensive logging with OSLog

### 3. ViewModels/CreditsViewModel.swift (570 lines)
**Location:** `/Users/alaindimabuyo/luid_projects/language-luid-ios/LanguageLuid/ViewModels/CreditsViewModel.swift`

**Key Components:**
- `@MainActor` for thread-safe UI updates
- `@Published` properties for SwiftUI reactive binding
- Auto-refresh on initialization
- Pagination support for transaction history

**Published Properties:**
```swift
@Published private(set) var credits: CreditBalance?
@Published private(set) var subscription: Subscription?
@Published private(set) var isLoading = false
@Published private(set) var isLoadingTransactions = false
@Published private(set) var isPurchasing = false
@Published private(set) var isCancelling = false
@Published var errorMessage: String?
@Published var successMessage: String?
@Published private(set) var transactions: [CreditTransaction] = []
```

**Core Methods:**
```swift
// Data Loading
func loadCredits() async
func loadSubscription() async
func loadTransactions(refresh: Bool) async
func refreshAll() async

// Purchases & Upgrades
func purchaseCredits(amount: Int) async
func upgradeToPro() async
func upgradeToYearly() async
func upgradeToSubscription(plan: SubscriptionPlan) async

// Subscription Management
func cancelSubscription() async
func reactivateSubscription() async
func openBillingPortal() async

// Payment Callbacks
func handlePaymentSuccess() async
func handlePaymentCancelled()
```

**Computed Properties:**
```swift
var totalCreditsDisplay: String
var subscriptionCreditsDisplay: String
var purchasedCreditsDisplay: String
var promotionalCreditsDisplay: String
var daysUntilReset: String
var renewalMessage: String?
var isSubscriptionCancelling: Bool
var subscriptionDaysRemaining: Int
```

**Mock Support:**
```swift
// For SwiftUI Previews
static func mock(...) -> CreditsViewModel
static func mockLoading() -> CreditsViewModel
static func mockWithError(_ error: String) -> CreditsViewModel
static func mockFree() -> CreditsViewModel
static func mockCancelled() -> CreditsViewModel
static func mockEmpty() -> CreditsViewModel
```

## Architecture Highlights

### 1. Swift Best Practices
- `@MainActor` for thread safety
- Async/await throughout
- Protocol-oriented where appropriate
- Value types (structs) for models
- Reference types (classes) for ViewModels
- Comprehensive error handling with typed errors

### 2. Codable with Snake Case
All models use automatic snake_case conversion:
```swift
enum CodingKeys: String, CodingKey {
    case totalCredits = "total_credits"
    case subscriptionCredits = "subscription_credits"
    case purchasedCredits = "purchased_credits"
    case promotionalCredits = "promotional_credits"
    case nextReset = "next_reset"
}
```

### 3. Type Safety
- Strong typing with enums for plans and statuses
- Identifiable protocol for SwiftUI List support
- Equatable for comparison and change detection
- Codable for JSON serialization

### 4. SwiftUI Integration
- `@Published` properties trigger view updates
- Computed properties for formatted display
- Mock data for previews
- Loading states for UI feedback

## Backend Endpoints Required

The system expects these endpoints on your backend:

```
GET  /api/users/credits                     # Fetch credit balance
GET  /api/users/credits/transactions        # Transaction history (paginated)
POST /api/users/credits/purchase            # Purchase credits

GET  /api/subscriptions/my-subscription     # Current subscription
GET  /api/subscriptions/plans               # Available plans
POST /api/subscriptions/create-checkout-session
POST /api/subscriptions/cancel
POST /api/subscriptions/reactivate
POST /api/subscriptions/billing-portal
```

These are already defined in `APIEndpoint` enum in AppConfig.swift.

## Usage Example

### Basic ViewModel Usage
```swift
import SwiftUI

struct CreditsView: View {
    @StateObject private var viewModel = CreditsViewModel()

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
            } else if let credits = viewModel.credits {
                VStack(alignment: .leading, spacing: 16) {
                    // Total Credits Display
                    HStack {
                        Text("Total Credits")
                            .font(.headline)
                        Spacer()
                        Text(viewModel.totalCreditsDisplay)
                            .font(.title)
                            .bold()
                    }

                    // Credit Breakdown
                    VStack(spacing: 8) {
                        CreditRow(
                            label: "Subscription Credits",
                            value: viewModel.subscriptionCreditsDisplay
                        )
                        CreditRow(
                            label: "Purchased Credits",
                            value: viewModel.purchasedCreditsDisplay
                        )
                        CreditRow(
                            label: "Promotional Credits",
                            value: viewModel.promotionalCreditsDisplay
                        )
                    }

                    // Reset Info
                    if let days = credits.daysUntilReset {
                        Text("Resets in \(viewModel.daysUntilReset)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Subscription Info
                    if let subscription = viewModel.subscription {
                        SubscriptionCard(subscription: subscription)
                    }

                    // Actions
                    if !viewModel.isPaidPlan {
                        Button("Upgrade to Pro") {
                            Task {
                                await viewModel.upgradeToPro()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Button("Purchase Credits") {
                        Task {
                            await viewModel.purchaseCredits(amount: 100)
                        }
                    }
                    .disabled(viewModel.isPurchasing)
                }
                .padding()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}

struct CreditRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}
```

### Transaction History
```swift
struct TransactionHistoryView: View {
    @StateObject private var viewModel = CreditsViewModel()

    var body: some View {
        List {
            ForEach(viewModel.transactions) { transaction in
                TransactionRow(transaction: transaction)
            }

            if viewModel.hasMoreTransactions {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .onAppear {
                        Task {
                            await viewModel.loadTransactions()
                        }
                    }
            }
        }
        .refreshable {
            await viewModel.loadTransactions(refresh: true)
        }
        .navigationTitle("Transaction History")
    }
}

struct TransactionRow: View {
    let transaction: CreditTransaction

    var body: some View {
        HStack {
            Image(systemName: transaction.type.icon)
                .foregroundColor(transaction.type.isDebit ? .red : .green)

            VStack(alignment: .leading) {
                Text(transaction.description)
                    .font(.body)
                Text(transaction.dateDisplay)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(transaction.formattedAmount)
                .font(.headline)
                .foregroundColor(transaction.type.isDebit ? .red : .green)
        }
    }
}
```

### Subscription Management
```swift
struct SubscriptionManagementView: View {
    @StateObject private var viewModel = CreditsViewModel()

    var body: some View {
        VStack(spacing: 20) {
            if let subscription = viewModel.subscription {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(subscription.plan.displayName)
                            .font(.title2)
                            .bold()

                        Spacer()

                        StatusBadge(status: subscription.status)
                    }

                    Text(subscription.renewalMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if subscription.isActive {
                        if subscription.cancelAtPeriodEnd {
                            Button("Reactivate Subscription") {
                                Task {
                                    await viewModel.reactivateSubscription()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button("Cancel Subscription") {
                                Task {
                                    await viewModel.cancelSubscription()
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(viewModel.isCancelling)
                        }
                    }

                    Button("Manage Billing") {
                        Task {
                            await viewModel.openBillingPortal()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                // Show upgrade options
                UpgradePlansView(viewModel: viewModel)
            }
        }
        .padding()
    }
}

struct StatusBadge: View {
    let status: SubscriptionStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.isActive ? Color.green : Color.orange)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
}
```

## Integration Checklist

- [x] Models with Codable support
- [x] Service layer with APIClient integration
- [x] ViewModel with @MainActor and async/await
- [x] Mock data for previews
- [x] Error handling throughout
- [x] Loading states for all operations
- [x] Pagination support for transactions
- [x] URL handling for Stripe checkout
- [x] Comprehensive logging
- [ ] Add views to project (examples provided above)
- [ ] Test with backend API
- [ ] Handle deep links for payment callbacks
- [ ] Add to main navigation

## Next Steps

1. **Add to Xcode Project**: Import the three Swift files into your Xcode project
2. **Backend Integration**: Ensure backend endpoints match expected contract
3. **Deep Linking**: Set up URL schemes for Stripe callback handling:
   - `languageluid://subscription/success`
   - `languageluid://subscription/cancel`
   - `languageluid://credits/purchase/success`
   - `languageluid://credits/purchase/cancel`
4. **Create UI Views**: Use the example views above as starting points
5. **Testing**: Use mock data for UI testing and previews

## Notes

- All credits are managed server-side for security
- Stripe handles payment processing
- Token-based authentication via existing APIClient
- Thread-safe with @MainActor
- Follows Swift API Design Guidelines
- Zero external dependencies (uses URLSession)
- Production-ready error handling and logging
