//
//  NotificationSettingsView.swift
//  LanguageLuid
//
//  Notification preferences and settings
//  Native iOS toggle controls
//

import SwiftUI

/// Notification settings view
struct NotificationSettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var pushNotificationsEnabled = true
    @State private var emailNotificationsEnabled = true

    // Learning notifications
    @State private var dailyReminder = true
    @State private var streakReminder = true
    @State private var goalAchievement = true
    @State private var lessonComplete = true

    // Social notifications
    @State private var friendRequests = true
    @State private var messages = true
    @State private var leaderboardUpdates = false

    // Marketing notifications
    @State private var promotions = false
    @State private var newsletter = true
    @State private var productUpdates = true

    @State private var hasChanges = false

    var body: some View {
        Form {
            // Master Controls
            Section {
                Toggle(isOn: $pushNotificationsEnabled) {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(LLColors.primary.color(for: colorScheme))
                            .frame(width: 24)

                        Text("Push Notifications")
                    }
                }
                .tint(LLColors.primary.color(for: colorScheme))

                Toggle(isOn: $emailNotificationsEnabled) {
                    HStack {
                        Image(systemName: "envelope.badge.fill")
                            .foregroundColor(LLColors.primary.color(for: colorScheme))
                            .frame(width: 24)

                        Text("Email Notifications")
                    }
                }
                .tint(LLColors.primary.color(for: colorScheme))
            } footer: {
                Text("Control how you receive notifications from LanguageLuid.")
            }

            // Learning Notifications
            Section {
                Toggle(isOn: $dailyReminder) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Reminder")
                            .font(LLTypography.body())
                        Text("Get reminded to practice each day")
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                }
                .tint(LLColors.primary.color(for: colorScheme))
                .disabled(!pushNotificationsEnabled)

                Toggle(isOn: $streakReminder) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Streak Reminder")
                            .font(LLTypography.body())
                        Text("Don't lose your streak!")
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                }
                .tint(LLColors.primary.color(for: colorScheme))
                .disabled(!pushNotificationsEnabled)

                Toggle(isOn: $goalAchievement) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Goal Achievement")
                            .font(LLTypography.body())
                        Text("Celebrate when you reach your goals")
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                }
                .tint(LLColors.primary.color(for: colorScheme))
                .disabled(!pushNotificationsEnabled)

                Toggle(isOn: $lessonComplete) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Lesson Complete")
                            .font(LLTypography.body())
                        Text("Get feedback after completing lessons")
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                }
                .tint(LLColors.primary.color(for: colorScheme))
                .disabled(!pushNotificationsEnabled)
            } header: {
                Text("Learning")
            } footer: {
                Text("Stay motivated with learning reminders and achievements.")
            }

            // Social Notifications
            Section {
                Toggle(isOn: $friendRequests) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Friend Requests")
                            .font(LLTypography.body())
                        Text("When someone sends you a friend request")
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                }
                .tint(LLColors.primary.color(for: colorScheme))
                .disabled(!pushNotificationsEnabled)

                Toggle(isOn: $messages) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Messages")
                            .font(LLTypography.body())
                        Text("New messages from friends")
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                }
                .tint(LLColors.primary.color(for: colorScheme))
                .disabled(!pushNotificationsEnabled)

                Toggle(isOn: $leaderboardUpdates) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Leaderboard Updates")
                            .font(LLTypography.body())
                        Text("Changes in your leaderboard ranking")
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                }
                .tint(LLColors.primary.color(for: colorScheme))
                .disabled(!pushNotificationsEnabled)
            } header: {
                Text("Social")
            } footer: {
                Text("Stay connected with your language learning community.")
            }

            // Marketing Notifications
            Section {
                Toggle(isOn: $promotions) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Promotions & Offers")
                            .font(LLTypography.body())
                        Text("Special deals and discounts")
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                }
                .tint(LLColors.primary.color(for: colorScheme))
                .disabled(!emailNotificationsEnabled)

                Toggle(isOn: $newsletter) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Newsletter")
                            .font(LLTypography.body())
                        Text("Monthly language learning tips")
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                }
                .tint(LLColors.primary.color(for: colorScheme))
                .disabled(!emailNotificationsEnabled)

                Toggle(isOn: $productUpdates) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Product Updates")
                            .font(LLTypography.body())
                        Text("New features and improvements")
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                }
                .tint(LLColors.primary.color(for: colorScheme))
                .disabled(!emailNotificationsEnabled)
            } header: {
                Text("Marketing")
            } footer: {
                Text("Occasional updates about LanguageLuid products and services.")
            }

            // System Settings Link
            Section {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Label("System Notification Settings", systemImage: "gear")
                            .foregroundColor(LLColors.foreground.color(for: colorScheme))

                        Spacer()

                        Image(systemName: "arrow.up.forward")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                }
            } footer: {
                Text("Manage notification permissions in iOS Settings.")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    saveSettings()
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
        .onChange(of: pushNotificationsEnabled) { _ in hasChanges = true }
        .onChange(of: emailNotificationsEnabled) { _ in hasChanges = true }
        .onChange(of: dailyReminder) { _ in hasChanges = true }
        .onChange(of: streakReminder) { _ in hasChanges = true }
        .onChange(of: goalAchievement) { _ in hasChanges = true }
        .onChange(of: lessonComplete) { _ in hasChanges = true }
        .onChange(of: friendRequests) { _ in hasChanges = true }
        .onChange(of: messages) { _ in hasChanges = true }
        .onChange(of: leaderboardUpdates) { _ in hasChanges = true }
        .onChange(of: promotions) { _ in hasChanges = true }
        .onChange(of: newsletter) { _ in hasChanges = true }
        .onChange(of: productUpdates) { _ in hasChanges = true }
    }

    // MARK: - Methods

    private func saveSettings() {
        guard hasChanges else { return }

        // TODO: Implement API call to save notification preferences
        print("Saving notification settings...")
    }
}

// MARK: - Preview

#Preview("Notification Settings") {
    NavigationStack {
        NotificationSettingsView()
    }
}
