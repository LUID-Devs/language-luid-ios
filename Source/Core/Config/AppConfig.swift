//
//  AppConfig.swift
//  LanguageLuid
//
//  Application configuration and environment variables
//  Language learning backend API configuration
//

import Foundation

enum AppConfig {
    // MARK: - API Configuration

    /// Base API URL (language-luid-backend)
    /// Uses 127.0.0.1 for simulator (Mac's localhost)
    /// Uses Mac's local IP for physical devices (so they can connect over WiFi)
    static var apiBaseURL: String {
        #if targetEnvironment(simulator)
        // Simulator: Use localhost
        return "http://127.0.0.1:5001/api"
        #else
        // Physical device: Use Mac's local IP address
        // Make sure your Mac and iPhone are on the same WiFi network!
        return "http://192.168.8.39:5001/api"
        #endif
    }

    /// API timeout in seconds
    static let apiTimeout: TimeInterval = 30

    /// File upload timeout (for audio files)
    static let uploadTimeout: TimeInterval = 60


    // MARK: - App Configuration

    /// App version
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    /// Build number
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// App name
    static var appName: String {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "Language Luid"
    }

    /// Bundle identifier
    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.luid.languageluid"
    }

    // MARK: - Learning Configuration

    /// Default target language
    static let defaultTargetLanguage = "es"

    /// Default native language
    static let defaultNativeLanguage = "en"

    /// Daily lesson goal
    static let dailyLessonGoal = 5

    /// XP per lesson completion
    static let xpPerLesson = 10

    /// Minimum audio recording duration (seconds)
    static let minRecordingDuration: TimeInterval = 0.5

    /// Maximum audio recording duration (seconds)
    static let maxRecordingDuration: TimeInterval = 30.0

    // MARK: - Feature Flags

    /// Enable speech recognition
    static let enableSpeechRecognition = true

    /// Enable text-to-speech
    static let enableTextToSpeech = true

    /// Enable offline mode
    static let enableOfflineMode = false

    /// Enable analytics
    static let enableAnalytics = false

    /// Enable push notifications
    static let enablePushNotifications = true

    /// Enable biometric authentication
    static let enableBiometrics = true

    /// Enable social features
    static let enableSocialFeatures = true

    /// Enable in-app purchases
    static let enableInAppPurchases = true

    // MARK: - Helper Methods

    /// Check if running in development mode
    static var isDevelopment: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    /// Check if running in simulator
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// Get full API URL for endpoint
    static func apiURL(for endpoint: String) -> String {
        let cleanEndpoint = endpoint.hasPrefix("/") ? endpoint : "/\(endpoint)"
        return "\(apiBaseURL)\(cleanEndpoint)"
    }

    /// Get app version display string
    static var versionDisplayString: String {
        return "\(appVersion) (\(buildNumber))"
    }
}

// MARK: - API Endpoints

enum APIEndpoint {
    // MARK: - Health Check
    static let health = "/health"

    // MARK: - Authentication
    static let login = "/auth/login"
    static let register = "/auth/register"
    static let verifyEmail = "/auth/verify-email"
    static let resendVerificationCode = "/auth/resend-code"
    static let forgotPassword = "/auth/forgot-password"
    static let resetPassword = "/auth/reset-password"
    static let refreshToken = "/auth/refresh"
    static let logout = "/auth/logout"
    static let me = "/auth/me"

    // MARK: - User Profile
    static let profile = "/users/profile"
    static let updateProfile = "/users/profile"
    static let userProgress = "/users/progress"
    static let userStreak = "/users/streak"
    static let updateLanguagePreferences = "/users/language-preferences"

    // MARK: - Languages
    static let languages = "/languages"

    // MARK: - Roadmaps
    static let roadmaps = "/roadmaps"
    static func roadmap(_ id: String) -> String {
        "/roadmaps/\(id)"
    }
    static func roadmapProgress(_ id: String) -> String {
        "/roadmaps/\(id)/progress"
    }
    static func enrollRoadmap(_ id: String) -> String {
        "/roadmaps/\(id)/enroll"
    }
    static let myRoadmaps = "/roadmaps/my-roadmaps"
    static let recommendedRoadmaps = "/roadmaps/recommended"

    // MARK: - Lessons
    static let lessons = "/lessons"
    static func lesson(_ id: String) -> String {
        "/lessons/\(id)"
    }
    static func lessonContent(_ id: String) -> String {
        "/lessons/\(id)/content"
    }
    static func startLesson(_ id: String) -> String {
        "/lessons/\(id)/start"
    }
    static func completeLesson(_ id: String) -> String {
        "/lessons/\(id)/complete"
    }
    static func lessonsByRoadmap(_ roadmapId: String) -> String {
        "/lessons?roadmapId=\(roadmapId)"
    }

    // MARK: - Exercises
    static let exercises = "/exercises"
    static func exercise(_ id: String) -> String {
        "/exercises/\(id)"
    }
    static func submitExercise(_ id: String) -> String {
        "/exercises/\(id)/submit"
    }
    static func exercisesByLesson(_ lessonId: String) -> String {
        "/exercises?lessonId=\(lessonId)"
    }

    // MARK: - Speech & Audio
    static let synthesizeSpeech = "/speech/synthesize"
    static let recognizeSpeech = "/speech/recognize"
    static let evaluatePronunciation = "/speech/evaluate-pronunciation"
    static let uploadAudio = "/speech/upload"

    // MARK: - Vocabulary
    static let vocabulary = "/vocabulary"
    static let myVocabulary = "/vocabulary/my-words"
    static func addToVocabulary(_ wordId: String) -> String {
        "/vocabulary/\(wordId)/add"
    }
    static func removeFromVocabulary(_ wordId: String) -> String {
        "/vocabulary/\(wordId)/remove"
    }
    static func reviewWord(_ wordId: String) -> String {
        "/vocabulary/\(wordId)/review"
    }

    // MARK: - Achievements
    static let achievements = "/achievements"
    static let myAchievements = "/achievements/my-achievements"
    static func unlockAchievement(_ id: String) -> String {
        "/achievements/\(id)/unlock"
    }

    // MARK: - Leaderboard
    static let leaderboard = "/leaderboard"
    static let weeklyLeaderboard = "/leaderboard/weekly"
    static let monthlyLeaderboard = "/leaderboard/monthly"
    static let allTimeLeaderboard = "/leaderboard/all-time"
    static let friendsLeaderboard = "/leaderboard/friends"

    // MARK: - Social
    static let friends = "/social/friends"
    static let friendRequests = "/social/friend-requests"
    static func sendFriendRequest(_ userId: String) -> String {
        "/social/friend-requests/\(userId)/send"
    }
    static func acceptFriendRequest(_ requestId: String) -> String {
        "/social/friend-requests/\(requestId)/accept"
    }
    static func rejectFriendRequest(_ requestId: String) -> String {
        "/social/friend-requests/\(requestId)/reject"
    }
    static func removeFriend(_ userId: String) -> String {
        "/social/friends/\(userId)/remove"
    }

    // MARK: - Subscriptions
    static let subscriptions = "/subscriptions"
    static let mySubscription = "/subscriptions/my-subscription"
    static let subscriptionPlans = "/subscriptions/plans"
    static let createCheckoutSession = "/subscriptions/create-checkout-session"
    static let cancelSubscription = "/subscriptions/cancel"
    static let updateSubscription = "/subscriptions/update"
    static let billingPortal = "/subscriptions/billing-portal"

    // MARK: - Notifications
    static let notifications = "/notifications"
    static let unreadNotifications = "/notifications/unread"
    static func markNotificationRead(_ id: String) -> String {
        "/notifications/\(id)/read"
    }
    static let markAllRead = "/notifications/mark-all-read"
    static let updateNotificationSettings = "/notifications/settings"

    // MARK: - Analytics
    static let trackEvent = "/analytics/track"
    static let sessionStart = "/analytics/session/start"
    static let sessionEnd = "/analytics/session/end"
}

// MARK: - Supported Languages

enum SupportedLanguage: String, CaseIterable, Codable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case russian = "ru"
    case japanese = "ja"
    case korean = "ko"
    case chinese = "zh"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .german: return "German"
        case .italian: return "Italian"
        case .portuguese: return "Portuguese"
        case .russian: return "Russian"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .chinese: return "Chinese"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .italian: return "🇮🇹"
        case .portuguese: return "🇧🇷"
        case .russian: return "🇷🇺"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        case .chinese: return "🇨🇳"
        }
    }
}

// MARK: - Proficiency Levels

enum ProficiencyLevel: String, CaseIterable, Codable {
    case beginner = "A1"
    case elementary = "A2"
    case intermediate = "B1"
    case upperIntermediate = "B2"
    case advanced = "C1"
    case proficient = "C2"

    var displayName: String {
        switch self {
        case .beginner: return "Beginner (A1)"
        case .elementary: return "Elementary (A2)"
        case .intermediate: return "Intermediate (B1)"
        case .upperIntermediate: return "Upper Intermediate (B2)"
        case .advanced: return "Advanced (C1)"
        case .proficient: return "Proficient (C2)"
        }
    }

    var description: String {
        switch self {
        case .beginner:
            return "Can understand and use familiar everyday expressions"
        case .elementary:
            return "Can communicate in simple and routine tasks"
        case .intermediate:
            return "Can deal with most situations while traveling"
        case .upperIntermediate:
            return "Can interact with a degree of fluency"
        case .advanced:
            return "Can express ideas fluently and spontaneously"
        case .proficient:
            return "Can understand with ease virtually everything"
        }
    }
}
