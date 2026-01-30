//
//  ProfileView.swift
//  LanguageLuid
//
//  Profile screen following Apple Human Interface Guidelines
//  Grouped list layout with native iOS patterns
//

import SwiftUI

/// Main profile view with user information and settings
struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var tabRouter: TabRouter
    @EnvironmentObject var drawerRouter: DrawerRouter

    @AppStorage(.themePreferenceKey) private var themePreference: ThemePreference = .system

    @State private var showingEditProfile = false
    @State private var showingChangePassword = false
    @State private var showingNotificationSettings = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingLogoutAlert = false

    var body: some View {
        List {
            // Profile Header Section
            profileHeaderSection

            // Account Section
            accountSection

            // Learning Section
            learningSection

            // App Settings Section
            appSettingsSection

            // Support Section
            supportSection

            // About Section
            aboutSection

            // Danger Zone Section
            dangerZoneSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingEditProfile) {
            NavigationStack {
                EditProfileView()
            }
        }
        .sheet(isPresented: $showingChangePassword) {
            NavigationStack {
                ChangePasswordView()
            }
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NavigationStack {
                NotificationSettingsView()
            }
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // TODO: Implement account deletion
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        .alert("Log Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                Task {
                    await authViewModel.logout()
                }
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }

    // MARK: - Profile Header Section

    private var profileHeaderSection: some View {
        Section {
            HStack(spacing: LLSpacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(LLColors.primary.color(for: colorScheme))
                        .frame(width: LLSpacing.avatarXL, height: LLSpacing.avatarXL)

                    Text(authViewModel.currentUser?.initials ?? "U")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(LLColors.primaryForeground.color(for: colorScheme))
                }

                VStack(alignment: .leading, spacing: LLSpacing.xs) {
                    // Name
                    Text(authViewModel.userDisplayName)
                        .font(LLTypography.h4())
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))

                    // Email
                    Text(authViewModel.userEmail)
                        .font(LLTypography.bodySmall())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                    // Membership Badge
                    HStack(spacing: LLSpacing.xs) {
                        Image(systemName: authViewModel.isPremiumUser ? "crown.fill" : "person.fill")
                            .font(.system(size: 10))
                            .foregroundColor(badgeForegroundColor)

                        Text(authViewModel.isPremiumUser ? "Premium" : "Free")
                            .font(LLTypography.captionSmall())
                            .foregroundColor(badgeForegroundColor)
                    }
                    .padding(.horizontal, LLSpacing.sm)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: LLSpacing.radiusSM)
                            .fill(badgeBackgroundColor)
                    )
                }

                Spacer()
            }
            .padding(.vertical, LLSpacing.sm)
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section {
            NavigationLink {
                EditProfileView()
            } label: {
                Label("Edit Profile", systemImage: "person.circle")
            }

            NavigationLink {
                ChangePasswordView()
            } label: {
                Label("Change Password", systemImage: "key.fill")
            }
        } header: {
            Text("Account")
        }
    }

    // MARK: - Learning Section

    private var learningSection: some View {
        Section {
            Button {
                tabRouter.selectedTab = .languages
            } label: {
                HStack {
                    Label("Languages", systemImage: "globe")
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))

                    Spacer()

                    if let currentLanguage = authViewModel.currentUser?.currentLanguage {
                        Text(currentLanguage.uppercased())
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
            }
        } header: {
            Text("Learning")
        }
    }

    // MARK: - App Settings Section

    private var appSettingsSection: some View {
        Section {
            // TODO: Re-enable when backend notification settings are implemented
//            NavigationLink {
//                NotificationSettingsView()
//            } label: {
//                Label("Notifications", systemImage: "app.badge")
//            }

            NavigationLink {
                ThemeSettingsView()
            } label: {
                HStack {
                    Label("Theme", systemImage: "paintbrush.fill")

                    Spacer()

                    Text(themePreference.displayName)
                        .font(LLTypography.caption())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
            }

            NavigationLink {
                LanguagePreferencesView()
            } label: {
                HStack {
                    Label("App Language", systemImage: "character.book.closed")

                    Spacer()

                    Text("English")
                        .font(LLTypography.caption())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
            }
        } header: {
            Text("App Settings")
        }
    }

    // MARK: - Support Section

    private var supportSection: some View {
        Section {
            NavigationLink {
                HelpCenterView()
            } label: {
                Label("Help Center", systemImage: "questionmark.circle")
            }

            NavigationLink {
                ContactView()
            } label: {
                Label("Contact Support", systemImage: "envelope")
            }

            Button {
                // TODO: Implement rate app functionality
                if let url = URL(string: "https://apps.apple.com/app/id123456789") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Label("Rate App", systemImage: "star.fill")
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))

                    Spacer()

                    Image(systemName: "arrow.up.forward")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
            }
        } header: {
            Text("Support")
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            NavigationLink {
                PrivacyPolicyView()
            } label: {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }

            NavigationLink {
                TermsOfServiceView()
            } label: {
                Label("Terms of Service", systemImage: "doc.text.fill")
            }

            HStack {
                Label("App Version", systemImage: "info.circle")

                Spacer()

                Text(appVersion)
                    .font(LLTypography.caption())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
        } header: {
            Text("About")
        }
    }

    // MARK: - Danger Zone Section

    private var dangerZoneSection: some View {
        Section {
            Button(role: .destructive) {
                showingDeleteAccountAlert = true
            } label: {
                Label("Delete Account", systemImage: "trash.fill")
            }

            Button(role: .destructive) {
                showingLogoutAlert = true
            } label: {
                Label("Log Out", systemImage: "arrow.right.square.fill")
            }
        } header: {
            Text("Danger Zone")
        } footer: {
            Text("Deleting your account will permanently remove all your data. This action cannot be undone.")
                .font(LLTypography.caption())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
    }

    // MARK: - Computed Properties

    private var badgeBackgroundColor: Color {
        if authViewModel.isPremiumUser {
            return Color.yellow.opacity(0.2)
        } else {
            return LLColors.muted.color(for: colorScheme)
        }
    }

    private var badgeForegroundColor: Color {
        if authViewModel.isPremiumUser {
            return Color.orange
        } else {
            return LLColors.mutedForeground.color(for: colorScheme)
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Placeholder Views

/// Theme settings view
struct ThemeSettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage(.themePreferenceKey) private var themePreference: ThemePreference = .system

    var body: some View {
        Form {
            Section {
                ForEach(ThemePreference.allCases, id: \.self) { theme in
                    Button {
                        themePreference = theme
                    } label: {
                        HStack(spacing: LLSpacing.md) {
                            // Theme icon
                            Image(systemName: theme.icon)
                                .font(.system(size: 24))
                                .foregroundColor(LLColors.primary.color(for: colorScheme))
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(LLColors.primary.color(for: colorScheme).opacity(0.1))
                                )

                            VStack(alignment: .leading, spacing: LLSpacing.xs) {
                                Text(theme.displayName)
                                    .font(LLTypography.bodyMedium())
                                    .foregroundColor(LLColors.foreground.color(for: colorScheme))

                                Text(theme.description)
                                    .font(LLTypography.caption())
                                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            // Checkmark for selected theme
                            if themePreference == theme {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(LLColors.primary.color(for: colorScheme))
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(.vertical, LLSpacing.xs)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Appearance")
            } footer: {
                Text("Your theme preference will be applied immediately across the entire app.")
            }
        }
        .navigationTitle("Theme")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Language preferences view
struct LanguagePreferencesView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedLanguage = "en"

    var body: some View {
        Form {
            Section {
                Picker("App Language", selection: $selectedLanguage) {
                    Text("English").tag("en")
                    Text("Spanish").tag("es")
                    Text("French").tag("fr")
                    Text("German").tag("de")
                    Text("Italian").tag("it")
                    Text("Portuguese").tag("pt")
                }
                .pickerStyle(.inline)
            } header: {
                Text("App Language")
            } footer: {
                Text("This controls the language used for app interface text, not the language you're learning.")
            }
        }
        .navigationTitle("App Language")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Help center view
struct HelpCenterView: View {
    @Environment(\.colorScheme) var colorScheme

    private let helpTopics = [
        HelpTopic(icon: "book.fill", title: "Getting Started", description: "Learn the basics of using LanguageLuid"),
        HelpTopic(icon: "graduationcap.fill", title: "Learning Tips", description: "Best practices for language learning"),
        HelpTopic(icon: "questionmark.circle.fill", title: "FAQs", description: "Frequently asked questions"),
        HelpTopic(icon: "wrench.fill", title: "Troubleshooting", description: "Fix common issues")
    ]

    var body: some View {
        List {
            ForEach(helpTopics) { topic in
                NavigationLink {
                    Text(topic.title)
                        .navigationTitle(topic.title)
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    HStack(spacing: LLSpacing.md) {
                        Image(systemName: topic.icon)
                            .font(.system(size: LLSpacing.iconLG))
                            .foregroundColor(LLColors.primary.color(for: colorScheme))
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(LLColors.primary.color(for: colorScheme).opacity(0.1))
                            )

                        VStack(alignment: .leading, spacing: LLSpacing.xs) {
                            Text(topic.title)
                                .font(LLTypography.bodyMedium())
                                .foregroundColor(LLColors.foreground.color(for: colorScheme))

                            Text(topic.description)
                                .font(LLTypography.caption())
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }
                    }
                    .padding(.vertical, LLSpacing.xs)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Help Center")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct HelpTopic: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

// MARK: - Preview

#Preview("Profile View") {
    NavigationStack {
        ProfileView()
            .environmentObject(AuthViewModel.mock())
            .environmentObject(TabRouter())
            .environmentObject(DrawerRouter())
    }
}
