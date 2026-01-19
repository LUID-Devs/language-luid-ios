//
//  QuickActionsCard.swift
//  LanguageLuid
//
//  Quick actions card for dashboard navigation
//

import SwiftUI

struct QuickActionsCard: View {
    // MARK: - Properties

    let onBrowseLanguages: () -> Void
    let onContinueLearning: (() -> Void)?
    let onViewProfile: () -> Void

    @Environment(\.colorScheme) var colorScheme

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            // Actions grid
            VStack(spacing: 12) {
                // Browse Languages
                QuickActionButton(
                    icon: "globe",
                    title: "Browse Languages",
                    subtitle: "Explore available courses",
                    color: .blue,
                    action: onBrowseLanguages
                )

                // Continue Learning (if available)
                if let continueAction = onContinueLearning {
                    QuickActionButton(
                        icon: "play.circle.fill",
                        title: "Continue Learning",
                        subtitle: "Resume your last lesson",
                        color: .green,
                        action: continueAction
                    )
                }

                // View Profile
                QuickActionButton(
                    icon: "person.circle.fill",
                    title: "View Profile",
                    subtitle: "See your progress",
                    color: .purple,
                    action: onViewProfile
                )
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

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(LLColors.background.color(for: colorScheme))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("With Continue Learning") {
    QuickActionsCard(
        onBrowseLanguages: {},
        onContinueLearning: {},
        onViewProfile: {}
    )
    .padding()
}

#Preview("Without Continue Learning") {
    QuickActionsCard(
        onBrowseLanguages: {},
        onContinueLearning: nil,
        onViewProfile: {}
    )
    .padding()
}
