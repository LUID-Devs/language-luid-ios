//
//  SubscriptionViewModel.swift
//  LanguageLuid
//
//  ViewModel for managing subscription and paywall UI state
//

import Foundation
import Combine

@MainActor
class SubscriptionViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Available subscription plans
    @Published private(set) var plans: [PaywallPlan] = []

    /// Selected plan
    @Published var selectedPlan: PaywallPlan?

    /// Current subscription status
    @Published private(set) var subscriptionStatus: RevenueCatStatus = .free

    /// Whether user has premium access
    @Published private(set) var isPremiumUser: Bool = false

    /// Loading state
    @Published private(set) var isLoading: Bool = false

    /// Whether a purchase is in progress
    @Published private(set) var isPurchasing: Bool = false

    /// Whether restore is in progress
    @Published private(set) var isRestoring: Bool = false

    /// Error message to display
    @Published var errorMessage: String?

    /// Success message to display
    @Published var successMessage: String?

    /// Show error alert
    @Published var showError: Bool = false

    /// Show success alert
    @Published var showSuccess: Bool = false

    // MARK: - Dependencies

    private let revenueCatManager: RevenueCatManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(revenueCatManager: RevenueCatManager = .shared) {
        self.revenueCatManager = revenueCatManager

        // Subscribe to RevenueCatManager changes
        revenueCatManager.$subscriptionStatus
            .assign(to: &$subscriptionStatus)

        revenueCatManager.$isPremiumUser
            .assign(to: &$isPremiumUser)

        revenueCatManager.$isLoading
            .assign(to: &$isLoading)

        revenueCatManager.$availablePlans
            .assign(to: &$plans)

        // Listen for subscription status changes
        NotificationCenter.default.publisher(for: .subscriptionStatusChanged)
            .sink { [weak self] _ in
                self?.handleSubscriptionChange()
            }
            .store(in: &cancellables)

        // Auto-select most popular plan
        if let popularPlan = PaywallPlan.paidPlans.first(where: { $0.isPopular }) {
            selectedPlan = popularPlan
        } else {
            selectedPlan = PaywallPlan.paidPlans.first
        }
    }

    // MARK: - Public Methods

    /// Load available subscription plans
    func loadPlans() async {
        isLoading = true
        errorMessage = nil

        do {
            try await revenueCatManager.fetchOfferings()
            plans = revenueCatManager.availablePlans

            // Auto-select popular plan if none selected
            if selectedPlan == nil {
                selectedPlan = plans.first(where: { $0.isPopular }) ?? plans.first
            }

        } catch {
            errorMessage = "Failed to load subscription plans. Please try again."
            showError = true
        }

        isLoading = false
    }

    /// Purchase selected plan
    func purchaseSelectedPlan() async {
        guard let plan = selectedPlan else {
            errorMessage = "Please select a subscription plan"
            showError = true
            return
        }

        await purchase(plan)
    }

    /// Purchase specific plan
    func purchase(_ plan: PaywallPlan) async {
        isPurchasing = true
        errorMessage = nil

        do {
            try await revenueCatManager.purchase(plan)

            successMessage = "Welcome to Premium! 🎉\nYou now have access to all lessons."
            showSuccess = true

        } catch let error as RevenueCatError {
            switch error {
            case .userCancelled:
                // Don't show error for user cancellation
                break
            default:
                errorMessage = error.localizedDescription
                showError = true
            }
        } catch {
            errorMessage = "Purchase failed. Please try again."
            showError = true
        }

        isPurchasing = false
    }

    /// Restore previous purchases
    func restorePurchases() async {
        isRestoring = true
        errorMessage = nil

        do {
            try await revenueCatManager.restorePurchases()

            if revenueCatManager.isPremiumUser {
                successMessage = "Purchases restored! You have premium access."
                showSuccess = true
            } else {
                errorMessage = "No previous purchases found."
                showError = true
            }

        } catch {
            errorMessage = "Failed to restore purchases. Please try again."
            showError = true
        }

        isRestoring = false
    }

    /// Check if a lesson is accessible
    func canAccessLesson(lessonNumber: Int) -> Bool {
        return revenueCatManager.canAccessLesson(lessonNumber: lessonNumber)
    }

    /// Dismiss error/success messages
    func dismissMessages() {
        showError = false
        showSuccess = false
        errorMessage = nil
        successMessage = nil
    }

    // MARK: - Computed Properties

    /// Whether any plan is being purchased
    var isProcessing: Bool {
        isPurchasing || isRestoring
    }

    /// Get annual savings percentage
    var annualSavings: String? {
        guard let annual = plans.first(where: { $0.id == RevenueCatConfig.annualProductId }),
              let savings = annual.savings else {
            return nil
        }
        return savings
    }

    /// Benefits of premium subscription
    var premiumBenefits: [String] {
        [
            "Unlock ALL lessons",
            "Advanced pronunciation AI",
            "Offline mode",
            "No ads",
            "Priority support",
            "Progress analytics",
            "Custom learning paths"
        ]
    }

    // MARK: - Private Methods

    private func handleSubscriptionChange() {
        // Refresh data when subscription changes
        Task {
            await loadPlans()
        }
    }

    // MARK: - Testing/Debug Methods

    #if DEBUG
    /// Set subscription status for testing
    func setStatusForTesting(_ status: RevenueCatStatus) {
        revenueCatManager.setSubscriptionStatus(status)
    }

    /// Grant premium for testing
    func grantPremiumForTesting() {
        revenueCatManager.grantPremiumForTesting()
    }

    /// Revoke premium for testing
    func revokePremiumForTesting() {
        revenueCatManager.revokePremiumForTesting()
    }
    #endif
}

// MARK: - Preview Support

#if DEBUG
extension SubscriptionViewModel {
    static var preview: SubscriptionViewModel {
        let vm = SubscriptionViewModel()
        vm.plans = PaywallPlan.paidPlans
        vm.selectedPlan = PaywallPlan.annual
        return vm
    }

    static var previewPremium: SubscriptionViewModel {
        let vm = SubscriptionViewModel()
        vm.plans = PaywallPlan.paidPlans
        vm.selectedPlan = PaywallPlan.annual
        vm.setStatusForTesting(.premium)
        return vm
    }
}
#endif
