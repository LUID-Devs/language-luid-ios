# Credits System Integration Guide

## Quick Start

### 1. Add Files to Xcode Project
The following files have been created and need to be added to your Xcode project:

```
LanguageLuid/
├── Models/
│   └── Credits.swift                  ✅ Created (486 lines)
├── Services/
│   └── SubscriptionService.swift      ✅ Created (471 lines)
└── ViewModels/
    └── CreditsViewModel.swift         ✅ Created (570 lines)
```

### 2. Backend Endpoint Requirements

Your backend needs these endpoints (most already exist in APIEndpoint):

```swift
// Already in AppConfig.swift ✅
APIEndpoint.mySubscription              // GET /subscriptions/my-subscription
APIEndpoint.subscriptionPlans           // GET /subscriptions/plans
APIEndpoint.createCheckoutSession       // POST /subscriptions/create-checkout-session
APIEndpoint.cancelSubscription          // POST /subscriptions/cancel
APIEndpoint.billingPortal               // POST /subscriptions/billing-portal

// Need to add to backend 🔧
GET  /api/users/credits                 // Fetch current credit balance
GET  /api/users/credits/transactions    // Fetch transaction history (paginated)
POST /api/users/credits/purchase        // Purchase additional credits
POST /api/subscriptions/reactivate      // Reactivate cancelled subscription
```

### 3. Expected Backend Response Formats

#### Credit Balance Response
```json
{
  "success": true,
  "data": {
    "total_credits": 850,
    "subscription_credits": 750,
    "purchased_credits": 50,
    "promotional_credits": 50,
    "plan": "pro",
    "next_reset": "2024-02-15T00:00:00.000Z"
  }
}
```

#### Subscription Response
```json
{
  "success": true,
  "data": {
    "id": "sub_123",
    "user_id": "user_456",
    "plan": "pro",
    "status": "active",
    "current_period_start": "2024-01-15T00:00:00.000Z",
    "current_period_end": "2024-02-15T00:00:00.000Z",
    "cancel_at_period_end": false,
    "cancelled_at": null,
    "trial_end": null,
    "created_at": "2024-01-15T00:00:00.000Z",
    "updated_at": "2024-01-15T00:00:00.000Z"
  }
}
```

#### Transaction History Response
```json
{
  "success": true,
  "data": [
    {
      "id": "tx_123",
      "user_id": "user_456",
      "type": "subscription",
      "amount": 1000,
      "balance_before": 50,
      "balance_after": 1050,
      "description": "Monthly subscription credits",
      "metadata": null,
      "created_at": "2024-01-15T00:00:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 100,
    "total_pages": 2
  }
}
```

#### Checkout Session Response
```json
{
  "success": true,
  "url": "https://checkout.stripe.com/c/pay/cs_test_...",
  "session_id": "cs_test_123"
}
```

### 4. URL Scheme Configuration

Add URL schemes to your `Info.plist` for Stripe callback handling:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>languageluid</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.luid.languageluid</string>
    </dict>
</array>
```

Handle deep links in your App struct:

```swift
import SwiftUI

@main
struct LanguageLuidApp: App {
    @StateObject private var creditsViewModel = CreditsViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(creditsViewModel)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "languageluid" else { return }
        
        switch url.host {
        case "subscription":
            if url.path == "/success" {
                Task {
                    await creditsViewModel.handlePaymentSuccess()
                }
            } else if url.path == "/cancel" {
                creditsViewModel.handlePaymentCancelled()
            }
        case "credits":
            if url.path == "/purchase/success" {
                Task {
                    await creditsViewModel.handlePaymentSuccess()
                }
            } else if url.path == "/purchase/cancel" {
                creditsViewModel.handlePaymentCancelled()
            }
        default:
            break
        }
    }
}
```

### 5. Usage in Views

#### Add to Settings/Profile View
```swift
import SwiftUI

struct ProfileView: View {
    @StateObject private var creditsViewModel = CreditsViewModel()
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        List {
            // User Info Section
            Section("Account") {
                HStack {
                    Text(authViewModel.userDisplayName)
                    Spacer()
                    if authViewModel.isPremiumUser {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            // Credits Section
            Section("Credits") {
                NavigationLink {
                    CreditsDetailView(viewModel: creditsViewModel)
                } label: {
                    HStack {
                        Image(systemName: "creditcard.fill")
                        Text("Credits")
                        Spacer()
                        if let credits = creditsViewModel.credits {
                            Text("\(credits.totalCredits)")
                                .foregroundColor(.secondary)
                        }
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            
            // Subscription Section
            Section("Subscription") {
                if let subscription = creditsViewModel.subscription {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(subscription.plan.displayName)
                            Spacer()
                            StatusBadge(status: subscription.status)
                        }
                        Text(subscription.renewalMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink("Manage Subscription") {
                        SubscriptionManagementView(viewModel: creditsViewModel)
                    }
                } else {
                    NavigationLink("Upgrade to Pro") {
                        UpgradeView(viewModel: creditsViewModel)
                    }
                }
            }
        }
        .navigationTitle("Profile")
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

#### Credits Detail View
```swift
struct CreditsDetailView: View {
    @ObservedObject var viewModel: CreditsViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Credit Balance Card
                CreditBalanceCard(viewModel: viewModel)
                
                // Purchase Options
                if !viewModel.isPaidPlan {
                    PurchaseOptionsCard(viewModel: viewModel)
                }
                
                // Transaction History
                TransactionHistorySection(viewModel: viewModel)
            }
            .padding()
        }
        .navigationTitle("Credits")
        .refreshable {
            await viewModel.refreshAll()
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

struct CreditBalanceCard: View {
    @ObservedObject var viewModel: CreditsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Credit Balance")
                .font(.headline)
            
            if let credits = viewModel.credits {
                HStack {
                    Text("\(credits.totalCredits)")
                        .font(.system(size: 48, weight: .bold))
                    
                    Spacer()
                    
                    // Progress Ring
                    Circle()
                        .trim(from: 0, to: 1 - viewModel.usagePercentage)
                        .stroke(Color.blue, lineWidth: 8)
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .overlay(
                            Text("\(Int((1 - viewModel.usagePercentage) * 100))%")
                                .font(.caption)
                                .bold()
                        )
                }
                
                Divider()
                
                VStack(spacing: 8) {
                    CreditBreakdownRow(
                        label: "Subscription",
                        value: viewModel.subscriptionCreditsDisplay,
                        icon: "star.fill",
                        color: .blue
                    )
                    CreditBreakdownRow(
                        label: "Purchased",
                        value: viewModel.purchasedCreditsDisplay,
                        icon: "cart.fill",
                        color: .green
                    )
                    CreditBreakdownRow(
                        label: "Promotional",
                        value: viewModel.promotionalCreditsDisplay,
                        icon: "gift.fill",
                        color: .purple
                    )
                }
                
                if let _ = credits.nextReset {
                    Divider()
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.secondary)
                        Text("Resets in \(viewModel.daysUntilReset)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            } else if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct CreditBreakdownRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .bold()
        }
    }
}

struct PurchaseOptionsCard: View {
    @ObservedObject var viewModel: CreditsViewModel
    
    let purchaseOptions = [
        (amount: 100, price: "$4.99"),
        (amount: 250, price: "$9.99"),
        (amount: 500, price: "$19.99"),
        (amount: 1000, price: "$34.99")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Purchase Credits")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(purchaseOptions, id: \.amount) { option in
                    Button {
                        Task {
                            await viewModel.purchaseCredits(amount: option.amount)
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(option.amount) Credits")
                                    .font(.headline)
                                Text(option.price)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isPurchasing)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct TransactionHistorySection: View {
    @ObservedObject var viewModel: CreditsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink("See All") {
                    TransactionHistoryView(viewModel: viewModel)
                }
                .font(.subheadline)
            }
            
            if viewModel.transactions.isEmpty {
                Text("No transactions yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.transactions.prefix(5)) { transaction in
                        TransactionRow(transaction: transaction)
                        if transaction.id != viewModel.transactions.prefix(5).last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
        }
        .padding()
    }
}

struct TransactionRow: View {
    let transaction: CreditTransaction
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.type.icon)
                .foregroundColor(transaction.type.isDebit ? .red : .green)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
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
        .padding()
    }
}
```

### 6. Testing

Use the mock data for SwiftUI previews:

```swift
#Preview("Credits Detail - Pro Plan") {
    NavigationStack {
        CreditsDetailView(viewModel: .mock())
    }
}

#Preview("Credits Detail - Free Plan") {
    NavigationStack {
        CreditsDetailView(viewModel: .mockFree())
    }
}

#Preview("Credits Detail - Loading") {
    NavigationStack {
        CreditsDetailView(viewModel: .mockLoading())
    }
}

#Preview("Credits Detail - Error") {
    NavigationStack {
        CreditsDetailView(viewModel: .mockWithError())
    }
}
```

### 7. Backend Implementation Tips

#### Python/Flask Example for /users/credits endpoint
```python
@app.route('/api/users/credits', methods=['GET'])
@jwt_required()
def get_user_credits():
    user_id = get_jwt_identity()
    user = User.query.get(user_id)
    
    subscription_credits = user.subscription_credits or 0
    purchased_credits = user.purchased_credits or 0
    promotional_credits = user.promotional_credits or 0
    
    return jsonify({
        'success': True,
        'data': {
            'total_credits': subscription_credits + purchased_credits + promotional_credits,
            'subscription_credits': subscription_credits,
            'purchased_credits': purchased_credits,
            'promotional_credits': promotional_credits,
            'plan': user.subscription_plan or 'free',
            'next_reset': user.credit_reset_date.isoformat() if user.credit_reset_date else None
        }
    })
```

## Summary

1. ✅ Three production-ready Swift files created (1,527 lines total)
2. ✅ Complete model layer with Codable support
3. ✅ Service layer with async/await
4. ✅ ViewModel with @MainActor and SwiftUI integration
5. ✅ Mock data for testing and previews
6. ✅ Comprehensive error handling
7. ✅ Integration examples provided

All files are located at:
- `/Users/alaindimabuyo/luid_projects/language-luid-ios/LanguageLuid/Models/Credits.swift`
- `/Users/alaindimabuyo/luid_projects/language-luid-ios/LanguageLuid/Services/SubscriptionService.swift`
- `/Users/alaindimabuyo/luid_projects/language-luid-ios/LanguageLuid/ViewModels/CreditsViewModel.swift`

Follow the integration steps above to add these to your app!
