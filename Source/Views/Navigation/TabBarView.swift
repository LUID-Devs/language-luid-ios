//
//  TabBarView.swift
//  LanguageLuid
//
//  Main tab bar navigation with 4 tabs
//  Custom styled tab bar using Language Luid design system
//

import SwiftUI

@MainActor
final class TabRouter: ObservableObject {
    @Published var selectedTab: TabBarView.Tab = .dashboard
}

@MainActor
final class DrawerRouter: ObservableObject {
    @Published var isOpen = false
    @Published var sheet: DrawerSheet?
}

enum DrawerSheet: Identifiable {
    case settings
    case credits
    case pricing
    case howItWorks
    case about
    case contact
    case privacy
    case terms
    case cookies

    var id: String {
        switch self {
        case .settings: return "settings"
        case .credits: return "credits"
        case .pricing: return "pricing"
        case .howItWorks: return "how-it-works"
        case .about: return "about"
        case .contact: return "contact"
        case .privacy: return "privacy"
        case .terms: return "terms"
        case .cookies: return "cookies"
        }
    }
}

/// Main tab bar view with 4 navigation tabs
struct TabBarView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var tabRouter = TabRouter()
    @StateObject private var drawerRouter = DrawerRouter()

    // MARK: - Tab Definition

    enum Tab: String, CaseIterable {
        case dashboard
        case languages
        case lessons
        case profile

        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .languages: return "Languages"
            case .lessons: return "Lessons"
            case .profile: return "Profile"
            }
        }

        var icon: String {
            switch self {
            case .dashboard: return "house"
            case .languages: return "globe"
            case .lessons: return "book"
            case .profile: return "person"
            }
        }

        var filledIcon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .languages: return "globe"
            case .lessons: return "book.fill"
            case .profile: return "person.fill"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content
            Group {
                switch tabRouter.selectedTab {
                case .dashboard:
                    DashboardView()
                case .languages:
                    LanguagesListView()
                case .lessons:
                    LessonsView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
            CustomTabBar(selectedTab: $tabRouter.selectedTab)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .environmentObject(tabRouter)
        .environmentObject(drawerRouter)
        .safeAreaInset(edge: .top) {
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        drawerRouter.isOpen = true
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))
                        .padding(12)
                        .background(
                            Circle()
                                .fill(LLColors.card.color(for: colorScheme))
                                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 2)
                        )
                }

                Spacer()
            }
            .padding(.horizontal, LLSpacing.lg)
            .padding(.top, LLSpacing.sm)
            .padding(.bottom, LLSpacing.sm)
            .background(LLColors.background.color(for: colorScheme))
        }
        .overlay {
            DrawerOverlay(
                authViewModel: authViewModel,
                tabRouter: tabRouter,
                drawerRouter: drawerRouter
            )
        }
        .sheet(item: $drawerRouter.sheet) { sheet in
            NavigationStack {
                drawerSheetView(sheet)
            }
        }
    }

    @ViewBuilder
    private func drawerSheetView(_ sheet: DrawerSheet) -> some View {
        switch sheet {
        case .settings:
            SettingsView()
        case .credits:
            CreditsDetailView()
        case .pricing:
            SubscriptionManagementView()
        case .howItWorks:
            HowItWorksView()
        case .about:
            AboutView()
        case .contact:
            ContactView()
        case .privacy:
            PrivacyPolicyView()
        case .terms:
            TermsOfServiceView()
        case .cookies:
            CookiePolicyView()
        }
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
            .padding(.bottom, 0)
            .background(
                LLColors.card.color(for: colorScheme)
                    .shadow(
                        color: Color.black.opacity(0.05),
                        radius: 10,
                        x: 0,
                        y: -5
                    )
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .background(
            LLColors.card.color(for: colorScheme)
                .ignoresSafeArea(edges: .bottom)
        )
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
                        .foregroundColor(LLColors.destructiveForeground.color(for: colorScheme))
                } else {
                    Text("99+")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(LLColors.destructiveForeground.color(for: colorScheme))
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
    @EnvironmentObject var tabRouter: TabRouter
    @EnvironmentObject var drawerRouter: DrawerRouter

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

                            LLButton("Browse Languages", style: .primary, size: .sm) {
                                tabRouter.selectedTab = .languages
                            }

                            LLButton("Open Settings", style: .outline, size: .sm) {
                                drawerRouter.sheet = .settings
                            }
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
    @EnvironmentObject var tabRouter: TabRouter
    @EnvironmentObject var drawerRouter: DrawerRouter

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

                    // Quick links
                    VStack(spacing: LLSpacing.sm) {
                        NavigationLink {
                            CreditsDetailView()
                        } label: {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .foregroundColor(LLColors.primary.color(for: colorScheme))
                                Text("Credits & Subscription")
                                    .font(LLTypography.body())
                                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                            }
                            .padding(LLSpacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                                    .fill(LLColors.card.color(for: colorScheme))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                                    .stroke(LLColors.border.color(for: colorScheme), lineWidth: 1)
                            )
                        }

                        LLButton("Manage Languages", style: .outline, size: .sm) {
                            tabRouter.selectedTab = .languages
                        }

                        LLButton("Account Settings", style: .outline, size: .sm) {
                            drawerRouter.sheet = .settings
                        }
                    }
                    .padding(.horizontal, LLSpacing.lg)
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
    private let accountLinks: [MoreLink] = [
        MoreLink(title: "Credits & Balance", destination: AnyView(CreditsDetailView()), icon: "creditcard"),
        MoreLink(title: "Subscription", destination: AnyView(SubscriptionManagementView()), icon: "crown")
    ]

    private let moreLinks: [MoreLink] = [
        MoreLink(title: "How It Works", destination: AnyView(HowItWorksView()), icon: "book.closed"),
        MoreLink(title: "About", destination: AnyView(AboutView()), icon: "info.circle"),
        MoreLink(title: "Contact", destination: AnyView(ContactView()), icon: "envelope"),
        MoreLink(title: "Privacy Policy", destination: AnyView(PrivacyPolicyView()), icon: "hand.raised"),
        MoreLink(title: "Terms of Service", destination: AnyView(TermsOfServiceView()), icon: "doc.text"),
        MoreLink(title: "Cookies", destination: AnyView(CookiePolicyView()), icon: "tray.full")
    ]

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

                    LLCard(style: .standard, padding: .lg) {
                        VStack(alignment: .leading, spacing: LLSpacing.md) {
                            Text("Account")
                                .font(LLTypography.h4())
                                .foregroundColor(LLColors.foreground.color(for: colorScheme))

                            VStack(spacing: LLSpacing.sm) {
                                ForEach(accountLinks) { link in
                                    NavigationLink(destination: link.destination) {
                                        HStack {
                                            if let icon = link.icon {
                                                Image(systemName: icon)
                                                    .foregroundColor(LLColors.primary.color(for: colorScheme))
                                                    .frame(width: 20)
                                            }

                                            Text(link.title)
                                                .font(LLTypography.body())
                                                .foregroundColor(LLColors.foreground.color(for: colorScheme))

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14))
                                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                        }
                                        .padding(.vertical, 8)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, LLSpacing.lg)

                    LLCard(style: .standard, padding: .lg) {
                        VStack(alignment: .leading, spacing: LLSpacing.md) {
                            Text("More")
                                .font(LLTypography.h4())
                                .foregroundColor(LLColors.foreground.color(for: colorScheme))

                            VStack(spacing: LLSpacing.sm) {
                                ForEach(moreLinks) { link in
                                    NavigationLink(destination: link.destination) {
                                        HStack {
                                            if let icon = link.icon {
                                                Image(systemName: icon)
                                                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                                    .frame(width: 20)
                                            }

                                            Text(link.title)
                                                .font(LLTypography.body())
                                                .foregroundColor(LLColors.foreground.color(for: colorScheme))

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14))
                                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                        }
                                        .padding(.vertical, 8)
                                    }
                                }
                            }
                        }
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

private struct MoreLink: Identifiable {
    let id = UUID()
    let title: String
    let destination: AnyView
    let icon: String?

    init(title: String, destination: AnyView, icon: String? = nil) {
        self.title = title
        self.destination = destination
        self.icon = icon
    }
}

private struct DrawerOverlay: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var tabRouter: TabRouter
    @ObservedObject var drawerRouter: DrawerRouter
    @Environment(\.colorScheme) var colorScheme

    private let width: CGFloat = 280

    var body: some View {
        ZStack(alignment: .leading) {
            if drawerRouter.isOpen {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        closeDrawer()
                    }

                drawerContent
                    .frame(width: width)
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: drawerRouter.isOpen)
    }

    private var drawerContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LLSpacing.lg) {
                // User Profile Section
                HStack(spacing: LLSpacing.sm) {
                    Circle()
                        .fill(LLColors.primary.color(for: colorScheme))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(authViewModel.userDisplayName.prefix(2))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(LLColors.primaryForeground.color(for: colorScheme))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(authViewModel.userDisplayName)
                            .font(LLTypography.bodyMedium())
                            .foregroundColor(LLColors.foreground.color(for: colorScheme))
                        Text(authViewModel.userEmail)
                            .font(LLTypography.captionSmall())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }

                    Spacer()
                }
                .padding(.top, LLSpacing.sm)
                .padding(.bottom, LLSpacing.sm)

                drawerSectionTitle("Main")
                drawerButton(
                    title: "Dashboard",
                    icon: "house",
                    isActive: tabRouter.selectedTab == .dashboard
                ) {
                    tabRouter.selectedTab = .dashboard
                    closeDrawer()
                }
                drawerButton(
                    title: "Languages",
                    icon: "globe",
                    isActive: tabRouter.selectedTab == .languages
                ) {
                    tabRouter.selectedTab = .languages
                    closeDrawer()
                }
                drawerButton(
                    title: "Lessons",
                    icon: "book",
                    isActive: tabRouter.selectedTab == .lessons
                ) {
                    tabRouter.selectedTab = .lessons
                    closeDrawer()
                }
                drawerButton(
                    title: "Profile",
                    icon: "person",
                    isActive: tabRouter.selectedTab == .profile
                ) {
                    tabRouter.selectedTab = .profile
                    closeDrawer()
                }

                drawerSectionTitle("Account")
                drawerButton(title: "Settings", icon: "gearshape") {
                    drawerRouter.sheet = .settings
                    closeDrawer()
                }
                drawerButton(title: "Credits", icon: "creditcard") {
                    drawerRouter.sheet = .credits
                    closeDrawer()
                }
                drawerButton(title: "Subscription", icon: "crown") {
                    drawerRouter.sheet = .pricing
                    closeDrawer()
                }

                drawerSectionTitle("Info")
                drawerButton(title: "How It Works", icon: "book.closed") {
                    drawerRouter.sheet = .howItWorks
                    closeDrawer()
                }
                drawerButton(title: "About", icon: "info.circle") {
                    drawerRouter.sheet = .about
                    closeDrawer()
                }
                drawerButton(title: "Contact", icon: "envelope") {
                    drawerRouter.sheet = .contact
                    closeDrawer()
                }

                drawerSectionTitle("Legal")
                drawerButton(title: "Privacy Policy", icon: "hand.raised") {
                    drawerRouter.sheet = .privacy
                    closeDrawer()
                }
                drawerButton(title: "Terms of Service", icon: "doc.text") {
                    drawerRouter.sheet = .terms
                    closeDrawer()
                }
                drawerButton(title: "Cookies", icon: "tray.full") {
                    drawerRouter.sheet = .cookies
                    closeDrawer()
                }

                Divider()
                    .padding(.top, LLSpacing.md)

                LLButton("Log Out", style: .destructive, size: .sm, fullWidth: true) {
                    Task {
                        await authViewModel.logout()
                    }
                    closeDrawer()
                }
            }
            .padding(LLSpacing.lg)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(LLColors.card.color(for: colorScheme))
    }

    private func drawerSectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(LLTypography.captionSmall())
            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            .tracking(LLTypography.letterSpacingWide)
            .padding(.top, LLSpacing.xs)
    }

    private func drawerButton(
        title: String,
        icon: String,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: LLSpacing.sm) {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                    .font(LLTypography.body())
                Spacer()
            }
            .foregroundColor(LLColors.foreground.color(for: colorScheme))
            .padding(.vertical, 8)
            .padding(.horizontal, LLSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                    .fill(isActive ? LLColors.muted.color(for: colorScheme) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func closeDrawer() {
        withAnimation(.easeInOut(duration: 0.2)) {
            drawerRouter.isOpen = false
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
