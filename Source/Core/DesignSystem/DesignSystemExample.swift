//
//  DesignSystemExample.swift
//  LanguageLuid
//
//  Design System Usage Examples
//  Demonstrates how to use the design system components
//

import SwiftUI

// MARK: - Example: Login Screen

struct LoginScreenExample: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: LLSpacing.xl) {
                // Logo/Header
                VStack(spacing: LLSpacing.md) {
                    Image(systemName: "globe")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: LLSpacing.iconXXL * 2, height: LLSpacing.iconXXL * 2)
                        .foregroundColor(LLColors.primary.adaptive)

                    Text("Welcome to Language Luid")
                        .h2()

                    Text("Learn languages naturally")
                        .bodyText()
                        .foregroundColor(LLColors.mutedForeground.adaptive)
                }
                .padding(.top, LLSpacing.xl)

                // Form Card
                LLCard(style: .elevated, padding: .lg) {
                    VStack(spacing: LLSpacing.lg) {
                        // Email Field
                        LLTextField(
                            "Enter your email",
                            text: $email,
                            label: "Email",
                            type: .email,
                            errorMessage: errorMessage,
                            leadingIcon: Image(systemName: "envelope")
                        )

                        // Password Field
                        LLTextField(
                            "Enter your password",
                            text: $password,
                            label: "Password",
                            type: .password
                        )

                        // Login Button
                        LLButton(
                            "Sign In",
                            style: .primary,
                            size: .lg,
                            isLoading: isLoading,
                            fullWidth: true
                        ) {
                            login()
                        }

                        // Divider
                        HStack {
                            Rectangle()
                                .fill(LLColors.border.adaptive)
                                .frame(height: LLSpacing.borderStandard)
                            Text("or")
                                .captionText()
                            Rectangle()
                                .fill(LLColors.border.adaptive)
                                .frame(height: LLSpacing.borderStandard)
                        }

                        // Social Login Buttons
                        VStack(spacing: LLSpacing.sm) {
                            LLButton(
                                "Continue with Google",
                                icon: Image(systemName: "globe"),
                                style: .outline,
                                size: .lg,
                                fullWidth: true
                            ) {
                                socialLogin()
                            }

                            LLButton(
                                "Continue with Apple",
                                icon: Image(systemName: "apple.logo"),
                                style: .outline,
                                size: .lg,
                                fullWidth: true
                            ) {
                                socialLogin()
                            }
                        }
                    }
                }

                // Footer Links
                HStack(spacing: LLSpacing.xs) {
                    Text("Don't have an account?")
                        .captionText()

                    Button("Sign Up") {
                        print("Sign up tapped")
                    }
                    .font(LLTypography.caption())
                    .foregroundColor(LLColors.primary.adaptive)
                }
            }
            .screenPadding()
        }
        .background(LLColors.background.adaptive)
    }

    private func login() {
        isLoading = true
        // Simulate login
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
        }
    }

    private func socialLogin() {
        print("Social login")
    }
}

// MARK: - Example: Language Selection Screen

struct LanguageSelectionExample: View {
    @State private var loadingState: LLLoadingState<[LanguageModel]> = .loading

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: LLSpacing.lg) {
                    // Header
                    VStack(spacing: LLSpacing.sm) {
                        Text("Choose Your Language")
                            .h2()

                        Text("Select a language to start learning")
                            .bodyText()
                            .foregroundColor(LLColors.mutedForeground.adaptive)
                    }
                    .padding(.top, LLSpacing.lg)

                    // Language Cards
                    VStack(spacing: LLSpacing.md) {
                        loadingContent
                    }
                }
                .screenPadding()
            }
            .background(LLColors.background.adaptive)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadLanguages()
            }
        }
    }

    @ViewBuilder
    private var loadingContent: some View {
        Group {
            switch loadingState {
            case .loading:
                LLSkeletonList(count: 5)

            case .loaded(let languages):
                ForEach(languages) { language in
                    LLLanguageCard(
                        languageName: language.name,
                        flagEmoji: language.flag,
                        lessonsCount: language.lessonsCount,
                        progress: language.progress
                    ) {
                        selectLanguage(language)
                    }
                }

            case .error:
                LLEmptyState(
                    icon: Image(systemName: "exclamationmark.triangle"),
                    title: "Unable to Load Languages",
                    description: "Please check your connection and try again",
                    actionTitle: "Retry",
                    action: { loadLanguages() }
                )

            case .idle:
                EmptyView()
            }
        }
    }

    private func loadLanguages() {
        loadingState = .loading

        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            loadingState = .loaded([
                LanguageModel(id: "1", name: "Spanish", flag: "🇪🇸", lessonsCount: 24, progress: 0.65),
                LanguageModel(id: "2", name: "French", flag: "🇫🇷", lessonsCount: 20, progress: 0.3),
                LanguageModel(id: "3", name: "German", flag: "🇩🇪", lessonsCount: 18, progress: 0.0),
                LanguageModel(id: "4", name: "Italian", flag: "🇮🇹", lessonsCount: 22, progress: 0.0),
                LanguageModel(id: "5", name: "Japanese", flag: "🇯🇵", lessonsCount: 30, progress: 0.0)
            ])
        }
    }

    private func selectLanguage(_ language: LanguageModel) {
        print("Selected language: \(language.name)")
    }
}

struct LanguageModel: Identifiable {
    let id: String
    let name: String
    let flag: String
    let lessonsCount: Int
    let progress: Double
}

// MARK: - Example: Lesson Progress Screen

struct LessonProgressExample: View {
    @State private var lessonProgress: Double = 0.0
    @State private var pronunciationScore: Double = 85
    @State private var isRecording = false

    var body: some View {
        ScrollView {
            VStack(spacing: LLSpacing.xl) {
                // Lesson Header
                LLCard(style: .elevated, padding: .lg) {
                    VStack(spacing: LLSpacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: LLSpacing.xs) {
                                Text("Lesson 5")
                                    .h4()

                                Text("Basic Greetings")
                                    .bodyText()
                                    .foregroundColor(LLColors.mutedForeground.adaptive)
                            }

                            Spacer()

                            LLBadge("B1", variant: .info, size: .sm)
                        }

                        // Progress
                        LLProgressBar(
                            progress: lessonProgress,
                            showPercentage: true
                        )
                    }
                }

                // Statistics Cards
                HStack(spacing: LLSpacing.md) {
                    StatCard(
                        icon: Image(systemName: "chart.line.uptrend.xyaxis"),
                        value: "\(Int(pronunciationScore))%",
                        label: "Pronunciation",
                        color: LLColors.success
                    )

                    StatCard(
                        icon: Image(systemName: "flame.fill"),
                        value: "7",
                        label: "Day Streak",
                        color: LLColors.warning
                    )

                    StatCard(
                        icon: Image(systemName: "star.fill"),
                        value: "245",
                        label: "XP",
                        color: LLColors.info
                    )
                }

                // Current Exercise
                LLCard(style: .standard, padding: .lg) {
                    VStack(spacing: LLSpacing.lg) {
                        VStack(alignment: .leading, spacing: LLSpacing.xs) {
                            Text("Speak this phrase")
                                .h4()
                            Text("Repeat after the audio")
                                .bodyText()
                                .foregroundColor(LLColors.mutedForeground.adaptive)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text("Buenos días")
                            .font(LLTypography.h3())
                            .foregroundColor(LLColors.primary.adaptive)

                        Text("Good morning")
                            .bodyText()
                            .foregroundColor(LLColors.mutedForeground.adaptive)

                        // Audio Controls
                        HStack(spacing: LLSpacing.lg) {
                            LLButton(
                                icon: Image(systemName: "speaker.wave.2.fill"),
                                style: .outline,
                                size: .icon
                            ) {
                                playAudio()
                            }

                            LLButton(
                                icon: Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill"),
                                style: isRecording ? .destructive : .primary,
                                size: .icon
                            ) {
                                toggleRecording()
                            }
                        }
                    }
                }

                // Achievements
                VStack(alignment: .leading, spacing: LLSpacing.md) {
                    Text("Recent Achievements")
                        .h4()

                    HStack(spacing: LLSpacing.lg) {
                        LLAchievementBadge(
                            title: "First Lesson",
                            icon: Image(systemName: "star.fill"),
                            isUnlocked: true
                        )

                        LLAchievementBadge(
                            title: "Fast Learner",
                            icon: Image(systemName: "bolt.fill"),
                            isUnlocked: true
                        )

                        LLAchievementBadge(
                            title: "Perfectionist",
                            icon: Image(systemName: "checkmark.seal.fill"),
                            isUnlocked: false
                        )
                    }
                }

                // Action Buttons
                VStack(spacing: LLSpacing.sm) {
                    LLButton(
                        "Continue",
                        style: .primary,
                        size: .lg,
                        fullWidth: true
                    ) {
                        continueLesson()
                    }

                    LLButton(
                        "Skip",
                        style: .ghost,
                        fullWidth: true
                    ) {
                        skipExercise()
                    }
                }
            }
            .screenPadding()
        }
        .background(LLColors.background.adaptive)
    }

    private func playAudio() {
        print("Playing audio")
    }

    private func toggleRecording() {
        isRecording.toggle()
    }

    private func continueLesson() {
        print("Continue lesson")
    }

    private func skipExercise() {
        print("Skip exercise")
    }
}

// Helper component for stat cards
struct StatCard: View {
    let icon: Image
    let value: String
    let label: String
    let color: ColorSet

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        LLCard(style: .elevated, padding: .md) {
            VStack(spacing: LLSpacing.sm) {
                icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: LLSpacing.iconLG, height: LLSpacing.iconLG)
                    .foregroundColor(color.color(for: colorScheme))

                Text(value)
                    .h4()
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))

                Text(label)
                    .captionText()
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Example: Settings Screen

struct SettingsScreenExample: View {
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    @State private var soundEnabled = true

    var body: some View {
        ScrollView {
            VStack(spacing: LLSpacing.xl) {
                // Profile Card
                LLCard(style: .elevated, padding: .lg) {
                    HStack(spacing: LLSpacing.md) {
                        Circle()
                            .fill(LLColors.primary.adaptive)
                            .frame(width: LLSpacing.avatarLG, height: LLSpacing.avatarLG)
                            .overlay(
                                Text("JD")
                                    .font(LLTypography.h4())
                                    .foregroundColor(.white)
                            )

                        VStack(alignment: .leading, spacing: LLSpacing.xs) {
                            Text("John Doe")
                                .h4()

                            Text("john.doe@example.com")
                                .font(LLTypography.bodySmall())
                                .foregroundColor(LLColors.mutedForeground.adaptive)
                        }

                        Spacer()

                        LLBadge("Pro", variant: .warning, size: .sm)
                    }
                }

                // Settings Sections
                VStack(spacing: LLSpacing.lg) {
                    SettingsSection(title: "Preferences") {
                        SettingsToggle(
                            title: "Notifications",
                            isOn: $notificationsEnabled
                        )

                        SettingsToggle(
                            title: "Dark Mode",
                            isOn: $darkModeEnabled
                        )

                        SettingsToggle(
                            title: "Sound Effects",
                            isOn: $soundEnabled
                        )
                    }

                    SettingsSection(title: "Account") {
                        SettingsButton(
                            title: "Edit Profile",
                            icon: Image(systemName: "person.fill")
                        ) {
                            print("Edit profile")
                        }

                        SettingsButton(
                            title: "Change Password",
                            icon: Image(systemName: "lock.fill")
                        ) {
                            print("Change password")
                        }

                        SettingsButton(
                            title: "Subscription",
                            icon: Image(systemName: "creditcard.fill")
                        ) {
                            print("Subscription")
                        }
                    }

                    SettingsSection(title: "Support") {
                        SettingsButton(
                            title: "Help Center",
                            icon: Image(systemName: "questionmark.circle.fill")
                        ) {
                            print("Help center")
                        }

                        SettingsButton(
                            title: "Privacy Policy",
                            icon: Image(systemName: "hand.raised.fill")
                        ) {
                            print("Privacy policy")
                        }
                    }

                    // Logout Button
                    LLButton(
                        "Log Out",
                        style: .destructive,
                        fullWidth: true
                    ) {
                        logout()
                    }
                }
            }
            .screenPadding()
        }
        .background(LLColors.background.adaptive)
    }

    private func logout() {
        print("Logging out")
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LLSpacing.md) {
            Text(title)
                .h5()
                .foregroundColor(LLColors.foreground.adaptive)

            LLCard(style: .standard, padding: .none) {
                VStack(spacing: 0) {
                    content
                }
            }
        }
    }
}

struct SettingsToggle: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(title, isOn: $isOn)
            .font(LLTypography.body())
            .padding(LLSpacing.paddingMD)
    }
}

struct SettingsButton: View {
    let title: String
    let icon: Image
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LLSpacing.md) {
                icon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: LLSpacing.iconMD, height: LLSpacing.iconMD)
                    .foregroundColor(LLColors.mutedForeground.adaptive)

                Text(title)
                    .font(LLTypography.body())
                    .foregroundColor(LLColors.foreground.adaptive)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(LLColors.mutedForeground.adaptive)
            }
            .padding(LLSpacing.paddingMD)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews

#Preview("Login Screen") {
    LoginScreenExample()
}

#Preview("Language Selection") {
    LanguageSelectionExample()
}

#Preview("Lesson Progress") {
    LessonProgressExample()
}

#Preview("Settings Screen") {
    SettingsScreenExample()
}
