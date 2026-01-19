//
//  DashboardView.swift
//  LanguageLuid
//
//  Dashboard view matching the web frontend design
//  Displays credit balance, quick actions, stats, and premium upgrade CTA
//

import SwiftUI

/// Main dashboard view for authenticated users
struct DashboardView: View {

    // MARK: - Environment & ViewModels

    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var creditsViewModel = CreditsViewModel()
    @Environment(\.colorScheme) var colorScheme

    // MARK: - State

    @State private var greeting = ""
    @State private var isRefreshing = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LLSpacing.lg) {
                // Header Section
                headerSection

                // Credit Balance Card
                creditBalanceCard

                // Quick Actions Card
                quickActionsCard

                // Stats Cards
                statsCardsSection

                // Premium Upgrade CTA (for free users only)
                if !creditsViewModel.isPaidPlan {
                    premiumUpgradeCTA
                }
            }
            .padding(LLSpacing.screenPaddingHorizontal)
            .padding(.top, LLSpacing.md)
            .padding(.bottom, LLSpacing.xxl)
        }
        .background(LLColors.background.adaptive)
        .refreshable {
            await refreshData()
        }
        .onAppear {
            updateGreeting()
            Task {
                await creditsViewModel.refreshAll()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: LLSpacing.xs) {
            Text("\(greeting), \(authViewModel.currentUser?.firstName ?? "there")")
                .font(LLTypography.h1())
                .fontWeight(.bold)
                .tracking(LLTypography.letterSpacingTight)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                .accessibilityAddTraits(.isHeader)

            Text("Ready to continue your language learning journey?")
                .font(LLTypography.body())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
    }

    // MARK: - Credit Balance Card

    private var creditBalanceCard: some View {
        LLCard(style: .standard, padding: .none) {
            VStack(alignment: .leading, spacing: 0) {
                // Card Header
                cardHeader

                // Card Content
                VStack(spacing: LLSpacing.lg) {
                    if creditsViewModel.isLoading && creditsViewModel.credits == nil {
                        loadingState
                    } else if let errorMsg = creditsViewModel.errorMessage {
                        errorState(message: errorMsg)
                    } else if let credits = creditsViewModel.credits {
                        creditContent(credits: credits)
                    } else {
                        emptyState
                    }
                }
                .padding(LLSpacing.cardContentPadding)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Credit Balance")
    }

    private var cardHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: LLSpacing.xs) {
                HStack(spacing: LLSpacing.sm) {
                    Image(systemName: "dollarsign.circle.fill")
                        .resizable()
                        .frame(width: LLSpacing.iconMD, height: LLSpacing.iconMD)
                        .foregroundColor(LLColors.primary.color(for: colorScheme))

                    Text("Credit Balance")
                        .font(LLTypography.h4())
                        .fontWeight(.semibold)
                        .foregroundColor(LLColors.cardForeground.color(for: colorScheme))
                }

                Text("Your available credits for AI-powered lessons and features")
                    .font(LLTypography.captionLarge())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }

            Spacer()

            LLButton(
                icon: Image(systemName: "arrow.clockwise"),
                style: .outline,
                size: .sm,
                isLoading: creditsViewModel.isLoading,
                isDisabled: creditsViewModel.isLoading
            ) {
                Task {
                    await creditsViewModel.loadCredits()
                }
            }
            .accessibilityLabel("Refresh credits")
        }
        .padding(LLSpacing.cardHeaderPadding)
    }

    private func creditContent(credits: CreditBalance) -> some View {
        VStack(spacing: LLSpacing.lg) {
            // Total Credits Display
            HStack {
                VStack(alignment: .leading, spacing: LLSpacing.xs) {
                    Text("Total Available")
                        .font(LLTypography.bodySmall())
                        .fontWeight(.medium)
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                    Text(credits.totalCredits.formatted())
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))
                        .accessibilityLabel("\(credits.totalCredits) credits available")
                }

                Spacer()

                VStack(alignment: .trailing, spacing: LLSpacing.xs) {
                    Text("Current Plan")
                        .font(LLTypography.bodySmall())
                        .fontWeight(.medium)
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                    LLBadge(
                        credits.plan.displayName,
                        variant: credits.isPaidPlan ? .success : .secondary,
                        size: .md
                    )
                }
            }
            .padding(LLSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                    .fill(LLColors.muted.color(for: colorScheme).opacity(0.5))
            )

            // Credit Breakdown
            creditBreakdown(credits: credits)

            // Next Reset Info
            nextResetSection(credits: credits)
        }
    }

    private func creditBreakdown(credits: CreditBalance) -> some View {
        VStack(spacing: LLSpacing.sm) {
            creditBreakdownItem(
                icon: "creditcard.fill",
                label: "Subscription",
                amount: credits.subscriptionCredits
            )

            creditBreakdownItem(
                icon: "dollarsign.circle.fill",
                label: "Purchased",
                amount: credits.purchasedCredits
            )

            creditBreakdownItem(
                icon: "gift.fill",
                label: "Promotional",
                amount: credits.promotionalCredits
            )
        }
    }

    private func creditBreakdownItem(icon: String, label: String, amount: Int) -> some View {
        HStack(spacing: LLSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: LLSpacing.radiusSM)
                    .fill(LLColors.secondary.color(for: colorScheme))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(LLTypography.captionLarge())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                Text(amount.formatted())
                    .font(LLTypography.h4())
                    .fontWeight(.semibold)
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
            }

            Spacer()
        }
        .padding(LLSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                .fill(LLColors.muted.color(for: colorScheme))
        )
    }

    private func nextResetSection(credits: CreditBalance) -> some View {
        VStack(spacing: 0) {
            Divider()
                .background(LLColors.border.color(for: colorScheme))
                .padding(.bottom, LLSpacing.md)

            HStack {
                HStack(spacing: LLSpacing.sm) {
                    Image(systemName: "clock.fill")
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                    if let resetDate = credits.resetDateDisplay {
                        Text("Credits reset on \(resetDate)")
                            .font(LLTypography.bodySmall())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    } else {
                        Text("No reset date available")
                            .font(LLTypography.bodySmall())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                }

                Spacer()

                LLButton("Get More Credits", style: .outline, size: .sm) {
                    // Navigate to pricing
                    print("Navigate to pricing")
                }
            }
        }
    }

    private var loadingState: some View {
        HStack {
            Spacer()
            VStack(spacing: LLSpacing.md) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: LLColors.primary.color(for: colorScheme)))
                    .scaleEffect(1.2)

                Text("Loading credits...")
                    .font(LLTypography.bodySmall())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
            .padding(.vertical, LLSpacing.xl)
            Spacer()
        }
    }

    private func errorState(message: String) -> some View {
        HStack(spacing: LLSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(LLColors.destructive.color(for: colorScheme))

            VStack(alignment: .leading, spacing: LLSpacing.xs) {
                Text("Failed to load credits")
                    .font(LLTypography.bodySmall())
                    .fontWeight(.medium)
                    .foregroundColor(LLColors.destructive.color(for: colorScheme))

                Text(message)
                    .font(LLTypography.captionLarge())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }

            Spacer()
        }
        .padding(LLSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                .fill(LLColors.destructive.color(for: colorScheme).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                        .strokeBorder(LLColors.destructive.color(for: colorScheme).opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var emptyState: some View {
        VStack(spacing: LLSpacing.md) {
            Image(systemName: "dollarsign.circle")
                .resizable()
                .frame(width: 48, height: 48)
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme).opacity(0.5))

            Text("No credit information available")
                .font(LLTypography.bodySmall())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

            LLButton("Load Credits", style: .outline, size: .sm) {
                Task {
                    await creditsViewModel.loadCredits()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LLSpacing.xl)
    }

    // MARK: - Quick Actions Card

    private var quickActionsCard: some View {
        LLCard(style: .standard, padding: .none) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: LLSpacing.xs) {
                    Text("Quick Actions")
                        .font(LLTypography.h4())
                        .fontWeight(.semibold)
                        .foregroundColor(LLColors.cardForeground.color(for: colorScheme))

                    Text("Get started with your language learning journey")
                        .font(LLTypography.captionLarge())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
                .padding(LLSpacing.cardHeaderPadding)

                // Actions Grid
                VStack(spacing: LLSpacing.sm) {
                    quickActionButton(
                        icon: "globe",
                        title: "Browse Languages",
                        subtitle: "Explore available languages",
                        action: {
                            print("Navigate to languages")
                        }
                    )

                    // Only show if user has active language
                    if let user = authViewModel.currentUser, !user.targetLanguage.isEmpty {
                        quickActionButton(
                            icon: "mic.fill",
                            title: "Continue Learning",
                            subtitle: user.targetLanguage.uppercased(),
                            action: {
                                print("Navigate to active language")
                            }
                        )
                    }

                    quickActionButton(
                        icon: "trophy.fill",
                        title: "View Profile",
                        subtitle: "See your progress",
                        action: {
                            print("Navigate to profile")
                        }
                    )
                }
                .padding(LLSpacing.cardContentPadding)
            }
        }
    }

    private func quickActionButton(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: LLSpacing.md) {
                Image(systemName: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: LLSpacing.iconMD, height: LLSpacing.iconMD)
                    .foregroundColor(LLColors.primary.color(for: colorScheme))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(LLTypography.body())
                        .fontWeight(.medium)
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))

                    Text(subtitle)
                        .font(LLTypography.captionLarge())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
            .padding(LLSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                    .strokeBorder(LLColors.border.color(for: colorScheme), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(title), \(subtitle)")
    }

    // MARK: - Stats Cards Section

    private var statsCardsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: LLSpacing.sm),
            GridItem(.flexible(), spacing: LLSpacing.sm)
        ], spacing: LLSpacing.sm) {
            statCard(
                icon: "book.fill",
                value: authViewModel.currentUser?.lessonsCompleted ?? 0,
                label: "Lessons",
                color: LLColors.primary
            )

            statCard(
                icon: "trophy.fill",
                value: authViewModel.currentUser?.totalXp ?? 0,
                label: "XP Earned",
                color: LLColors.warning
            )

            statCard(
                icon: "target",
                value: 0,
                label: "Accuracy",
                suffix: "%",
                color: LLColors.success
            )

            statCard(
                icon: "flame.fill",
                value: authViewModel.currentUser?.currentStreak ?? 0,
                label: "Day Streak",
                color: LLColors.destructive
            )
        }
    }

    private func statCard(
        icon: String,
        value: Int,
        label: String,
        suffix: String = "",
        color: ColorSet
    ) -> some View {
        LLCard(style: .filled, padding: .md) {
            VStack(spacing: LLSpacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: LLSpacing.iconMD, height: LLSpacing.iconMD)
                        .foregroundColor(color.color(for: colorScheme))

                    Spacer()
                }

                VStack(alignment: .leading, spacing: LLSpacing.xs) {
                    Text("\(value)\(suffix)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))

                    Text(label)
                        .font(LLTypography.bodySmall())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    // MARK: - Premium Upgrade CTA

    private var premiumUpgradeCTA: some View {
        LLCard(style: .outlined, padding: .lg) {
            VStack(alignment: .leading, spacing: LLSpacing.lg) {
                VStack(alignment: .leading, spacing: LLSpacing.md) {
                    Text("Unlock Premium Features")
                        .font(LLTypography.h3())
                        .fontWeight(.semibold)
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))

                    Text("Get unlimited lessons, advanced AI conversations, and detailed analytics.")
                        .font(LLTypography.bodySmall())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                    VStack(alignment: .leading, spacing: LLSpacing.sm) {
                        featureItem(icon: "infinity", text: "Unlimited lessons")
                        featureItem(icon: "waveform", text: "Advanced speech analysis")
                        featureItem(icon: "star.fill", text: "Exclusive challenges")
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("$10")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(LLColors.foreground.color(for: colorScheme))

                            Text("/month")
                                .font(LLTypography.bodySmall())
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }

                        Text("or $99/year (save 17%)")
                            .font(LLTypography.captionLarge())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }

                    Spacer()

                    LLButton("Upgrade Now", style: .primary, size: .md) {
                        print("Navigate to pricing")
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: LLSpacing.radiusLG)
                .strokeBorder(LLColors.primary.color(for: colorScheme).opacity(0.2), lineWidth: 2)
        )
    }

    private func featureItem(icon: String, text: String) -> some View {
        HStack(spacing: LLSpacing.sm) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
                .foregroundColor(LLColors.primary.color(for: colorScheme))

            Text(text)
                .font(LLTypography.bodySmall())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
        }
    }

    // MARK: - Helper Methods

    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())

        if hour < 12 {
            greeting = "Good morning"
        } else if hour < 18 {
            greeting = "Good afternoon"
        } else {
            greeting = "Good evening"
        }
    }

    private func refreshData() async {
        isRefreshing = true
        await creditsViewModel.refreshAll()
        await authViewModel.refreshUserProfile()
        isRefreshing = false
    }
}

// MARK: - Previews
// TODO: Fix previews - ambiguous init() calls due to missing mock data
/*
#Preview("Dashboard - Paid User") {
    DashboardView()
        .environmentObject(AuthViewModel.mock(user: .mock))
        .onAppear {
            // Preview with mock data
        }
}

#Preview("Dashboard - Free User") {
    DashboardView()
        .environmentObject(AuthViewModel.mock(user: .mockBeginner))
}

#Preview("Dashboard - Loading") {
    DashboardView()
        .environmentObject(AuthViewModel.mockLoading())
}

#Preview("Dashboard - Dark Mode") {
    DashboardView()
        .environmentObject(AuthViewModel.mock(user: .mock))
        .preferredColorScheme(.dark)
}
*/
