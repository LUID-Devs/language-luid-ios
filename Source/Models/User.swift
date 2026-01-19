//
//  User.swift
//  LanguageLuid
//
//  User model for language learning app
//

import Foundation

/// Application User
struct User: Identifiable, Codable, Hashable {
    let id: String
    let email: String
    let firstName: String?
    let lastName: String?
    let username: String?
    let avatar: String?
    let nativeLanguage: String?
    let currentLanguage: String?
    let proficiencyLevel: String?
    let cefrLevel: String?
    let streak: Int?
    let totalPracticeMinutes: Int?
    let dailyGoalMinutes: Int?
    let subscriptionType: String?
    let subscriptionStatus: String?
    let emailVerified: Bool?
    let role: String?
    let createdAt: String?
    let updatedAt: String?

    // Computed properties for backward compatibility
    var targetLanguage: String { currentLanguage ?? "es" }
    var totalXp: Int { totalPracticeMinutes ?? 0 }
    var currentStreak: Int { streak ?? 0 }
    var longestStreak: Int { streak ?? 0 }
    var lessonsCompleted: Int { 0 }
    var isPremium: Bool { subscriptionType == "premium" || subscriptionType == "pro" }

    enum CodingKeys: String, CodingKey {
        case id, email, firstName, lastName, username, avatar
        case nativeLanguage, currentLanguage, proficiencyLevel, cefrLevel
        case streak, totalPracticeMinutes, dailyGoalMinutes
        case subscriptionType, subscriptionStatus, emailVerified, role
        case createdAt, updatedAt
    }

    /// Full name computed property
    var fullName: String {
        let first = firstName ?? ""
        let last = lastName ?? ""
        let combined = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        return combined.isEmpty ? (username ?? email.components(separatedBy: "@").first ?? "User") : combined
    }

    /// Display name (prefers username, then full name, then email)
    var displayName: String {
        if let username = username, !username.isEmpty {
            return username
        }
        return fullName
    }

    /// Initials for avatar
    var initials: String {
        if let firstName = firstName, let lastName = lastName {
            return "\(firstName.prefix(1))\(lastName.prefix(1))".uppercased()
        }
        if let username = username {
            return String(username.prefix(2)).uppercased()
        }
        return String(email.prefix(2)).uppercased()
    }

    /// XP display string
    var xpDisplay: String {
        if totalXp >= 1000 {
            return String(format: "%.1fk", Double(totalXp) / 1000.0)
        }
        return "\(totalXp)"
    }

    /// Has active streak
    var hasStreak: Bool {
        return currentStreak > 0
    }

    /// Proficiency level display
    var proficiencyDisplay: String {
        return proficiencyLevel ?? cefrLevel ?? "Beginner"
    }
}

// MARK: - Mock Data

extension User {
    static let mock = User(
        id: UUID().uuidString,
        email: "user@example.com",
        firstName: "John",
        lastName: "Doe",
        username: "johndoe",
        avatar: nil,
        nativeLanguage: "en-US",
        currentLanguage: "es",
        proficiencyLevel: "intermediate",
        cefrLevel: "B1",
        streak: 7,
        totalPracticeMinutes: 1250,
        dailyGoalMinutes: 30,
        subscriptionType: "premium",
        subscriptionStatus: "active",
        emailVerified: true,
        role: "user",
        createdAt: "2025-12-20T00:00:00Z",
        updatedAt: "2026-01-20T00:00:00Z"
    )

    static let mockBeginner = User(
        id: UUID().uuidString,
        email: "beginner@example.com",
        firstName: "Jane",
        lastName: "Smith",
        username: "janesmith",
        avatar: nil,
        nativeLanguage: "en-US",
        currentLanguage: "fr",
        proficiencyLevel: "beginner",
        cefrLevel: "A1",
        streak: 3,
        totalPracticeMinutes: 150,
        dailyGoalMinutes: 10,
        subscriptionType: "free",
        subscriptionStatus: "inactive",
        emailVerified: true,
        role: "user",
        createdAt: "2026-01-13T00:00:00Z",
        updatedAt: "2026-01-20T00:00:00Z"
    )
}
