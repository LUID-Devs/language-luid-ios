//
//  TabBarView.swift
//  LanguageLuid
//
//  Main tab bar navigation with 5 tabs
//  Custom styled tab bar using Language Luid design system
//

import SwiftUI

/// Main tab bar view with 5 navigation tabs
struct TabBarView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab: Tab = .dashboard

    // MARK: - Tab Definition

    enum Tab: String, CaseIterable {
        case dashboard
        case languages
        case lessons
        case profile
        case settings

        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .languages: return "Languages"
            case .lessons: return "Lessons"
            case .profile: return "Profile"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .dashboard: return "house"
            case .languages: return "globe"
            case .lessons: return "book"
            case .profile: return "person"
            case .settings: return "gearshape"
            }
        }

        var filledIcon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .languages: return "globe"
            case .lessons: return "book.fill"
            case .profile: return "person.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                case .languages:
                    LanguagesListView()
                case .lessons:
                    LessonsView()
                case .profile:
                    ProfileView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// MARK: - Custom Tab Bar

/// Custom styled tab bar
struct CustomTabBar: View {
    @Binding var selectedTab: TabBarView.Tab
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authViewModel: AuthViewModel

    // Badge counts (can be connected to view models later)
    @State private var notificationBadge: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // Top Border
            Rectangle()
                .fill(LLColors.border.color(for: colorScheme))
                .frame(height: 0.5)

            // Tab Bar Content
            HStack(spacing: 0) {
                ForEach(TabBarView.Tab.allCases, id: \.self) { tab in
                    TabBarButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        badgeCount: badgeCount(for: tab),
                        action: {
                            selectedTab = tab
                            // Haptic feedback
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }
                    )
                }
            }
            .frame(height: 60)
            .background(
                LLColors.card.color(for: colorScheme)
                    .shadow(
                        color: Color.black.opacity(0.05),
                        radius: 10,
                        x: 0,
                        y: -5
                    )
            )
        }
    }

    /// Get badge count for specific tab
    private func badgeCount(for tab: TabBarView.Tab) -> Int? {
        switch tab {
        case .dashboard:
            return notificationBadge > 0 ? notificationBadge : nil
        case .profile:
            // Show badge if email not verified
            return !authViewModel.isEmailVerified ? 1 : nil
        default:
            return nil
        }
    }
}

// MARK: - Tab Bar Button

/// Individual tab bar button
struct TabBarButton: View {
    let tab: TabBarView.Tab
    let isSelected: Bool
    let badgeCount: Int?
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    // Icon
                    Image(systemName: isSelected ? tab.filledIcon : tab.icon)
                        .font(.system(size: 24, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(iconColor)
                        .frame(height: 24)

                    // Badge
                    if let count = badgeCount {
                        BadgeView(count: count)
                            .offset(x: 12, y: -8)
                    }
                }

                // Label
                Text(tab.title)
                    .font(LLTypography.captionSmall())
                    .foregroundColor(labelColor)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(TabBarButtonStyle())
    }

    private var iconColor: Color {
        isSelected
            ? LLColors.primary.color(for: colorScheme)
            : LLColors.mutedForeground.color(for: colorScheme)
    }

    private var labelColor: Color {
        isSelected
            ? LLColors.foreground.color(for: colorScheme)
            : LLColors.mutedForeground.color(for: colorScheme)
    }
}

// MARK: - Badge View

/// Badge notification indicator
struct BadgeView: View {
    let count: Int
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if count > 0 {
            ZStack {
                Circle()
                    .fill(LLColors.destructive.color(for: colorScheme))
                    .frame(width: badgeSize, height: badgeSize)

                if count <= 99 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("99+")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }

    private var badgeSize: CGFloat {
        count > 9 ? 20 : 16
    }
}

// MARK: - Tab Bar Button Style

/// Custom button style for tab bar buttons
struct TabBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Placeholder Views
// Note: DashboardView is defined in Source/Views/Dashboard/DashboardView.swift

/// Languages placeholder view
struct LanguagesView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: LLSpacing.lg) {
                    LLCard(style: .standard, padding: .lg) {
                        VStack(spacing: LLSpacing.md) {
                            Image(systemName: "globe.americas.fill")
                                .font(.system(size: 48))
                                .foregroundColor(LLColors.primary.color(for: colorScheme))

                            Text("Languages Coming Soon")
                                .font(LLTypography.h4())
                                .foregroundColor(LLColors.foreground.color(for: colorScheme))

                            Text("Browse and select languages to learn")
                                .font(LLTypography.body())
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                .multilineTextAlignment(.center)
                        }
                        .padding(LLSpacing.xl)
                    }
                    .padding(.horizontal, LLSpacing.lg)
                }
                .padding(.top, LLSpacing.lg)
                .padding(.bottom, 80) // Tab bar padding
            }
            .background(LLColors.background.color(for: colorScheme))
            .navigationTitle("Languages")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

/// Lessons placeholder view
struct LessonsView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: LLSpacing.lg) {
                    LLCard(style: .standard, padding: .lg) {
                        VStack(spacing: LLSpacing.md) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 48))
                                .foregroundColor(LLColors.primary.color(for: colorScheme))

                            Text("Lessons Coming Soon")
                                .font(LLTypography.h4())
                                .foregroundColor(LLColors.foreground.color(for: colorScheme))

                            Text("Access your language lessons and exercises")
                                .font(LLTypography.body())
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                .multilineTextAlignment(.center)
                        }
                        .padding(LLSpacing.xl)
                    }
                    .padding(.horizontal, LLSpacing.lg)
                }
                .padding(.top, LLSpacing.lg)
                .padding(.bottom, 80) // Tab bar padding
            }
            .background(LLColors.background.color(for: colorScheme))
            .navigationTitle("Lessons")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

/// Profile placeholder view
struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: LLSpacing.lg) {
                    // User Info Card
                    LLCard(style: .standard, padding: .lg) {
                        VStack(spacing: LLSpacing.md) {
                            // Avatar
                            ZStack {
                                Circle()
                                    .fill(LLColors.primary.color(for: colorScheme))
                                    .frame(width: 80, height: 80)

                                Text(authViewModel.currentUser?.initials ?? "U")
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundColor(LLColors.primaryForeground.color(for: colorScheme))
                            }

                            // Name
                            Text(authViewModel.userDisplayName)
                                .font(LLTypography.h4())
                                .foregroundColor(LLColors.foreground.color(for: colorScheme))

                            // Email
                            Text(authViewModel.userEmail)
                                .font(LLTypography.body())
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                            // Stats
                            HStack(spacing: LLSpacing.xl) {
                                StatItem(
                                    value: "\(authViewModel.currentUser?.totalXp ?? 0)",
                                    label: "XP"
                                )
                                StatItem(
                                    value: "\(authViewModel.currentUser?.currentStreak ?? 0)",
                                    label: "Day Streak"
                                )
                                StatItem(
                                    value: "\(authViewModel.currentUser?.lessonsCompleted ?? 0)",
                                    label: "Lessons"
                                )
                            }
                            .padding(.top, LLSpacing.md)
                        }
                        .padding(LLSpacing.md)
                    }
                    .padding(.horizontal, LLSpacing.lg)

                    // Placeholder
                    Text("Profile features coming soon")
                        .font(LLTypography.body())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
                .padding(.top, LLSpacing.lg)
                .padding(.bottom, 80) // Tab bar padding
            }
            .background(LLColors.background.color(for: colorScheme))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

/// Settings placeholder view
struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showingLogoutAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: LLSpacing.lg) {
                    LLCard(style: .standard, padding: .lg) {
                        VStack(spacing: LLSpacing.md) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 48))
                                .foregroundColor(LLColors.primary.color(for: colorScheme))

                            Text("Settings Coming Soon")
                                .font(LLTypography.h4())
                                .foregroundColor(LLColors.foreground.color(for: colorScheme))

                            Text("Customize your learning experience")
                                .font(LLTypography.body())
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                .multilineTextAlignment(.center)
                        }
                        .padding(LLSpacing.xl)
                    }
                    .padding(.horizontal, LLSpacing.lg)

                    // Logout Button
                    LLButton(
                        "Log Out",
                        style: .destructive,
                        fullWidth: false
                    ) {
                        showingLogoutAlert = true
                    }
                    .padding(.horizontal, LLSpacing.lg)
                }
                .padding(.top, LLSpacing.lg)
                .padding(.bottom, 80) // Tab bar padding
            }
            .background(LLColors.background.color(for: colorScheme))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
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
    }
}

// MARK: - Helper Views

/// Stat item for profile
struct StatItem: View {
    let value: String
    let label: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: LLSpacing.xs) {
            Text(value)
                .font(LLTypography.h5())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            Text(label)
                .font(LLTypography.caption())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
    }
}

// MARK: - Preview Support
// TODO: Fix previews - AuthViewModel.mock() references unavailable mock data
/*
#Preview("Tab Bar View") {
    TabBarView()
        .environmentObject(AuthViewModel.mock())
}

#Preview("Dashboard") {
    DashboardView()
        .environmentObject(AuthViewModel.mock())
}

#Preview("Profile") {
    ProfileView()
        .environmentObject(AuthViewModel.mock())
}

#Preview("Settings") {
    SettingsView()
        .environmentObject(AuthViewModel.mock())
}
*/
