//
//  TabBarView.swift
//  LanguageLuid
//
//  Main tab bar navigation with 4 tabs
//  Refactored to use native iOS TabView for better HIG compliance
//

import SwiftUI

// MARK: - Tab Router

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

/// Main tab bar view with 4 navigation tabs - Native iOS implementation
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
        TabView(selection: $tabRouter.selectedTab) {
            dashboardTab
            languagesTab
            lessonsTab
            profileTab
        }
        .tint(LLColors.primary.color(for: colorScheme))
        .environmentObject(tabRouter)
        .environmentObject(drawerRouter)
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
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        drawerRouter.isOpen = true
                    }
                } label: {
                    Label("Menu", systemImage: "line.3.horizontal")
                        .labelStyle(.iconOnly)
                }
                .accessibilityLabel("Open menu")
                .accessibilityHint("Double tap to open the navigation menu")
            }
        }
    }

    // MARK: - Tab Views

    private var dashboardTab: some View {
        NavigationStack {
            DashboardView()
        }
        .tabItem {
            Label(Tab.dashboard.title, systemImage: Tab.dashboard.filledIcon)
        }
        .tag(Tab.dashboard)
    }

    private var languagesTab: some View {
        NavigationStack {
            LanguagesListView()
        }
        .tabItem {
            Label(Tab.languages.title, systemImage: Tab.languages.filledIcon)
        }
        .tag(Tab.languages)
    }

    private var lessonsTab: some View {
        NavigationStack {
            ContinueLearningView()
        }
        .tabItem {
            Label(Tab.lessons.title, systemImage: Tab.lessons.filledIcon)
        }
        .tag(Tab.lessons)
    }

    @ViewBuilder
    private var profileTab: some View {
        let tab = NavigationStack {
            ProfileView()
        }
        .tabItem {
            Label(Tab.profile.title, systemImage: Tab.profile.filledIcon)
        }
        .tag(Tab.profile)

        if !authViewModel.isEmailVerified {
            tab.badge(1)
        } else {
            tab
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
        }
        .background(LLColors.background.color(for: colorScheme))
        .navigationTitle("Lessons")
        .navigationBarTitleDisplayMode(.large)
    }
}

// Note: ProfileView is now defined in Source/Views/Profile/ProfileView.swift

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
