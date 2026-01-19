//
//  ProgressStatsCard.swift
//  LanguageLuid
//
//  Progress statistics card for dashboard
//

import SwiftUI

struct ProgressStatsCard: View {
    // MARK: - Properties

    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Your Progress")
                .font(.headline)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            if let user = authViewModel.currentUser {
                // Stats grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    // Total XP
                    ProgressStatCard(
                        icon: "star.fill",
                        value: "\(user.totalXp ?? 0)",
                        label: "Total XP",
                        color: .yellow
                    )

                    // Current Streak
                    ProgressStatCard(
                        icon: "flame.fill",
                        value: "\(user.currentStreak ?? 0)",
                        label: "Day Streak",
                        color: .orange
                    )

                    // Lessons Completed
                    ProgressStatCard(
                        icon: "checkmark.circle.fill",
                        value: "\(user.lessonsCompleted ?? 0)",
                        label: "Lessons",
                        color: .green
                    )

                    // Premium Status
                    ProgressStatCard(
                        icon: user.isPremium == true ? "crown.fill" : "lock.fill",
                        value: user.isPremium == true ? "Pro" : "Free",
                        label: "Plan",
                        color: user.isPremium == true ? .purple : LLColors.mutedForeground.color(for: colorScheme)
                    )
                }
            } else {
                // Loading or error state
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LLColors.card.color(for: colorScheme))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Progress Stat Card

private struct ProgressStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            // Value
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            // Label
            Text(label)
                .font(.caption)
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LLColors.background.color(for: colorScheme))
        )
    }
}

// MARK: - Preview
// TODO: Fix preview - cannot set @Published currentUser with private setter
/*
#Preview {
    let viewModel = AuthViewModel()
    viewModel.currentUser = User(
        id: "user_123",
        email: "test@example.com",
        firstName: "John",
        lastName: "Doe",
        role: .user,
        isEmailVerified: true,
        subscriptionType: .pro,
        nativeLanguage: "en",
        targetLanguage: "es",
        totalXp: 1250,
        currentStreak: 7,
        longestStreak: 15,
        lessonsCompleted: 24,
        isPremium: true
    )

    return ProgressStatsCard(authViewModel: viewModel)
        .padding()
}
*/
