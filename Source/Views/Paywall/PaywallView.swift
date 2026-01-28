//
//  PaywallView.swift
//  LanguageLuid
//
//  Professional iOS-native paywall for premium subscriptions
//  Follows Apple Human Interface Guidelines
//

import SwiftUI

struct PaywallView: View {
    // MARK: - Properties

    @StateObject private var viewModel = SubscriptionViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    /// Optional completion handler when premium is granted
    var onPremiumGranted: (() -> Void)?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                LLColors.background.color(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: LLSpacing.xl) {
                        // Header Section
                        headerSection

                        // Benefits Section
                        benefitsSection

                        // Plans Section
                        plansSection

                        // Purchase Button
                        purchaseButton

                        // Restore Purchases
                        restorePurchasesButton

                        // Terms and Privacy
                        legalSection
                    }
                    .padding(LLSpacing.lg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    closeButton
                }
            }
            .task {
                await viewModel.loadPlans()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .alert("Success", isPresented: $viewModel.showSuccess) {
                Button("Continue") {
                    onPremiumGranted?()
                    dismiss()
                }
            } message: {
                Text(viewModel.successMessage ?? "Success!")
            }
            .overlay {
                if viewModel.isProcessing {
                    processingOverlay
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: LLSpacing.md) {
            // Icon
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.yellow, Color.orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.orange.opacity(0.3), radius: 10, x: 0, y: 5)

            // Title
            Text("Unlock Premium")
                .font(LLTypography.h1())
                .fontWeight(.bold)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            // Subtitle
            Text("Get unlimited access to all lessons and features")
                .font(LLTypography.body())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, LLSpacing.lg)
    }

    // MARK: - Benefits Section

    private var benefitsSection: some View {
        VStack(spacing: LLSpacing.md) {
            ForEach(viewModel.premiumBenefits, id: \.self) { benefit in
                BenefitRow(benefit: benefit)
            }
        }
    }

    // MARK: - Plans Section

    private var plansSection: some View {
        VStack(spacing: LLSpacing.md) {
            Text("Choose Your Plan")
                .font(LLTypography.h3())
                .fontWeight(.semibold)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(viewModel.plans) { plan in
                PaywallPlanCard(
                    plan: plan,
                    isSelected: viewModel.selectedPlan?.id == plan.id
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.selectedPlan = plan
                    }
                }
            }
        }
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        LLButton(
            purchaseButtonTitle,
            style: .primary,
            size: .lg,
            isLoading: viewModel.isPurchasing
        ) {
            Task {
                await viewModel.purchaseSelectedPlan()
            }
        }
        .disabled(viewModel.selectedPlan == nil || viewModel.isProcessing)
    }

    private var purchaseButtonTitle: String {
        if let plan = viewModel.selectedPlan {
            return "Subscribe for \(plan.price)"
        }
        return "Select a Plan"
    }

    // MARK: - Restore Purchases

    private var restorePurchasesButton: some View {
        Button(action: {
            Task {
                await viewModel.restorePurchases()
            }
        }) {
            Text("Restore Purchases")
                .font(LLTypography.body())
                .foregroundColor(LLColors.primary.color(for: colorScheme))
        }
        .disabled(viewModel.isProcessing)
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        VStack(spacing: LLSpacing.xs) {
            Text("By subscribing, you agree to our")
                .font(LLTypography.captionSmall())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

            HStack(spacing: 4) {
                Button("Terms of Service") {
                    // TODO: Open terms URL
                }
                .font(LLTypography.captionSmall())

                Text("and")
                    .font(LLTypography.captionSmall())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                Button("Privacy Policy") {
                    // TODO: Open privacy URL
                }
                .font(LLTypography.captionSmall())
            }
            .foregroundColor(LLColors.primary.color(for: colorScheme))

            Text("Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period")
                .font(LLTypography.captionSmall())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.top, LLSpacing.sm)
        }
        .padding(.top, LLSpacing.lg)
    }

    // MARK: - Close Button

    private var closeButton: some View {
        Button(action: {
            dismiss()
        }) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                .symbolRenderingMode(.hierarchical)
        }
    }

    // MARK: - Processing Overlay

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: LLSpacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text(viewModel.isPurchasing ? "Processing purchase..." : "Restoring purchases...")
                    .font(LLTypography.body())
                    .foregroundColor(.white)
            }
            .padding(LLSpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: LLSpacing.radiusLG)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }
}

// MARK: - Benefit Row Component

private struct BenefitRow: View {
    let benefit: String

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: LLSpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(LLColors.success.color(for: colorScheme))

            Text(benefit)
                .font(LLTypography.body())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            Spacer()
        }
        .padding(.vertical, LLSpacing.xs)
    }
}

// MARK: - Preview

#Preview("Paywall") {
    PaywallView()
}

#Preview("Paywall - Dark Mode") {
    PaywallView()
        .preferredColorScheme(.dark)
}
