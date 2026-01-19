//
//  Roadmap.swift
//  LanguageLuid
//
//  Language roadmap model matching backend API
//

import Foundation

// MARK: - Roadmap Model

struct Roadmap: Codable, Identifiable, Hashable {
    let id: String
    let languageId: String
    let name: String
    let slug: String
    let description: String?
    let methodology: String
    let totalLessons: Int
    let maxLessonNumber: Int
    let cefrLevelsSupported: [CEFRLevel]
    let estimatedTotalHours: Double?
    let version: String
    let isActive: Bool
    let isPublished: Bool
    let publishedAt: Date?
    let metadata: [String: AnyCodable]?
    let createdAt: Date
    let updatedAt: Date

    // Optional relationships (populated by specific endpoints)
    let language: Language?
    let curriculumGroups: [CurriculumGroup]?
    let lessons: [RoadmapLesson]?

    enum CodingKeys: String, CodingKey {
        case id, languageId, name, slug, description, methodology
        case totalLessons, maxLessonNumber, cefrLevelsSupported
        case estimatedTotalHours, version, isActive, isPublished
        case publishedAt, metadata, createdAt, updatedAt
        case language, curriculumGroups, lessons
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Roadmap, rhs: Roadmap) -> Bool {
        lhs.id == rhs.id
    }

    // Computed properties
    var completedLessons: Int {
        // This will be calculated from user progress
        0
    }

    var progressPercentage: Double {
        guard totalLessons > 0 else { return 0 }
        return (Double(completedLessons) / Double(totalLessons)) * 100
    }

    var estimatedTotalHoursFormatted: String {
        guard let hours = estimatedTotalHours else { return "N/A" }
        if hours >= 1.0 {
            return String(format: "%.0f hours", hours)
        } else {
            return String(format: "%.0f minutes", hours * 60)
        }
    }

    var languageName: String {
        language?.name ?? "Unknown Language"
    }

    var languageFlag: String {
        // If flag is an emoji, use it directly
        if let flag = language?.flag, !flag.contains("http") {
            return flag
        }

        // Otherwise, map language code to flag emoji
        guard let code = language?.code else { return "🌐" }

        // Map language codes to flag emojis
        let flagMap: [String: String] = [
            "es": "🇪🇸", "es-ES": "🇪🇸",
            "pt": "🇧🇷", "pt-BR": "🇧🇷", "pt-PT": "🇵🇹",
            "fr": "🇫🇷", "fr-FR": "🇫🇷",
            "it": "🇮🇹", "it-IT": "🇮🇹",
            "de": "🇩🇪", "de-DE": "🇩🇪",
            "zh": "🇨🇳", "zh-CN": "🇨🇳",
            "ko": "🇰🇷", "ko-KR": "🇰🇷",
            "ja": "🇯🇵", "ja-JP": "🇯🇵",
            "en": "🇺🇸", "en-US": "🇺🇸", "en-GB": "🇬🇧",
            "ru": "🇷🇺", "ru-RU": "🇷🇺",
            "ar": "🇸🇦", "ar-SA": "🇸🇦"
        ]

        return flagMap[code] ?? "🌐"
    }

    var displayName: String {
        "\(languageFlag) \(name)"
    }

    var cefrLevelsDisplay: String {
        guard !cefrLevelsSupported.isEmpty else { return "All Levels" }
        let levels = cefrLevelsSupported.sorted { $0.rawValue < $1.rawValue }
        if levels.count == CEFRLevel.allCases.count {
            return "A1-C2"
        } else if levels.count > 2 {
            return "\(levels.first?.rawValue ?? "")-\(levels.last?.rawValue ?? "")"
        } else {
            return levels.map { $0.rawValue }.joined(separator: ", ")
        }
    }
}

// MARK: - Roadmap Statistics

struct RoadmapStats: Codable {
    let totalLessons: Int
    let byLevel: [String: Int]
    let byCategory: [String: Int]
    let byDifficulty: DifficultyStats
    let totalMinutes: Int
    let totalHours: Double
    let madrigalGapsFilled: Int

    enum CodingKeys: String, CodingKey {
        case totalLessons, byLevel, byCategory, byDifficulty
        case totalMinutes, totalHours, madrigalGapsFilled
    }

    struct DifficultyStats: Codable {
        let easy: Int
        let medium: Int
        let hard: Int
        let expert: Int
    }

    var totalHoursFormatted: String {
        String(format: "%.1f hours", totalHours)
    }

    var averageLessonMinutes: Int {
        totalLessons > 0 ? totalMinutes / totalLessons : 0
    }
}

// MARK: - CEFR Progress

struct CEFRProgress: Codable {
    let level: CEFRLevel
    let lessonsCount: Int
    let totalMinutes: Int
    let lessons: [RoadmapLesson]?

    enum CodingKeys: String, CodingKey {
        case level, lessonsCount, totalMinutes, lessons
    }

    var totalHours: Double {
        Double(totalMinutes) / 60.0
    }

    var totalHoursFormatted: String {
        String(format: "%.1f hours", totalHours)
    }
}

// MARK: - Roadmap Lesson (Simplified)

struct RoadmapLesson: Codable, Identifiable, Hashable {
    let id: String
    let roadmapId: String
    let curriculumGroupId: String?
    let lessonNumber: Int
    let title: String
    let subtitle: String?
    let description: String?
    let cefrLevel: CEFRLevel
    let category: LessonCategory
    let lessonType: LessonType?
    let difficulty: Int
    let estimatedMinutes: Int
    let isActive: Bool
    let isPublished: Bool
    let fillsMadrigalGap: Bool
    let madrigalGapType: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, roadmapId, curriculumGroupId, lessonNumber
        case title, subtitle, description, cefrLevel, category, lessonType
        case difficulty, estimatedMinutes, isActive, isPublished
        case fillsMadrigalGap, madrigalGapType, createdAt, updatedAt
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: RoadmapLesson, rhs: RoadmapLesson) -> Bool {
        lhs.id == rhs.id
    }

    var lessonNumberFormatted: String {
        "L\(lessonNumber)"
    }

    var displayTitle: String {
        "\(lessonNumberFormatted): \(title)"
    }

    var difficultyStars: String {
        String(repeating: "⭐", count: min(difficulty, 10))
    }
}

// MARK: - Lesson Category

enum LessonCategory: String, Codable, CaseIterable {
    case vocabulary
    case grammar
    case conversation
    case pronunciation
    case listening
    case culture
    case business
    case travel
    case assessment
    case review

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .vocabulary:
            return "book.fill"
        case .grammar:
            return "textformat"
        case .conversation:
            return "bubble.left.and.bubble.right.fill"
        case .pronunciation:
            return "waveform"
        case .listening:
            return "ear.fill"
        case .culture:
            return "globe"
        case .business:
            return "briefcase.fill"
        case .travel:
            return "airplane"
        case .assessment:
            return "checkmark.seal.fill"
        case .review:
            return "arrow.clockwise"
        }
    }
}

// MARK: - Lesson Type

enum LessonType: String, Codable {
    case standard
    case cognate
    case verbConjugation = "verb_conjugation"
    case conversationPractice = "conversation_practice"
    case aiConversation = "ai_conversation"
    case listening
    case review
    case assessment
    case challenge

    var displayName: String {
        switch self {
        case .standard:
            return "Standard"
        case .cognate:
            return "Cognate"
        case .verbConjugation:
            return "Verb Conjugation"
        case .conversationPractice:
            return "Conversation Practice"
        case .aiConversation:
            return "AI Conversation"
        case .listening:
            return "Listening"
        case .review:
            return "Review"
        case .assessment:
            return "Assessment"
        case .challenge:
            return "Challenge"
        }
    }
}

// MARK: - Mock Data for Previews
// TODO: Re-enable after fixing Language mock data
/*
extension Roadmap {
    static let mockSpanishRoadmap = Roadmap(
        id: "660e8400-e29b-41d4-a716-446655440000",
        languageId: Language.mockSpanish.id,
        name: "Spanish Learning Roadmap",
        slug: "spanish-roadmap",
        description: "Complete Spanish learning path from A1 to C2 using the Madrigal method with modern enhancements.",
        methodology: "madrigal",
        totalLessons: 97,
        maxLessonNumber: 100,
        cefrLevelsSupported: CEFRLevel.allCases,
        estimatedTotalHours: 120.0,
        version: "1.0.0",
        isActive: true,
        isPublished: true,
        publishedAt: Date(),
        metadata: nil,
        createdAt: Date(),
        updatedAt: Date(),
        language: Language.mockSpanish,
        curriculumGroups: nil,
        lessons: nil
    )

    static let mockFrenchRoadmap = Roadmap(
        id: "660e8400-e29b-41d4-a716-446655440001",
        languageId: Language.mockFrench.id,
        name: "French Learning Roadmap",
        slug: "french-roadmap",
        description: "Comprehensive French learning journey from beginner to advanced.",
        methodology: "madrigal",
        totalLessons: 85,
        maxLessonNumber: 100,
        cefrLevelsSupported: [.a1, .a2, .b1, .b2],
        estimatedTotalHours: 95.0,
        version: "1.0.0",
        isActive: true,
        isPublished: true,
        publishedAt: Date(),
        metadata: nil,
        createdAt: Date(),
        updatedAt: Date(),
        language: Language.mockFrench,
        curriculumGroups: nil,
        lessons: nil
    )

    static let mockRoadmaps = [mockSpanishRoadmap, mockFrenchRoadmap]
}
*/

extension RoadmapStats {
    static let mock = RoadmapStats(
        totalLessons: 97,
        byLevel: [
            "A1": 20,
            "A2": 18,
            "B1": 22,
            "B2": 19,
            "C1": 12,
            "C2": 6
        ],
        byCategory: [
            "vocabulary": 25,
            "grammar": 22,
            "conversation": 18,
            "pronunciation": 10,
            "listening": 8,
            "culture": 6,
            "assessment": 8
        ],
        byDifficulty: RoadmapStats.DifficultyStats(
            easy: 30,
            medium: 35,
            hard: 22,
            expert: 10
        ),
        totalMinutes: 5820,
        totalHours: 97.0,
        madrigalGapsFilled: 15
    )
}

// TODO: Re-enable after fixing Roadmap mock data
/*
extension RoadmapLesson {
    static let mock = RoadmapLesson(
        id: "770e8400-e29b-41d4-a716-446655440000",
        roadmapId: Roadmap.mockSpanishRoadmap.id,
        curriculumGroupId: nil,
        lessonNumber: 1,
        title: "Spanish Cognates - 1000 Words",
        subtitle: "Learn 1000+ Spanish words you already know",
        description: "Discover how many Spanish words you can instantly recognize through English-Spanish cognates.",
        cefrLevel: .a1,
        category: .vocabulary,
        lessonType: .cognate,
        difficulty: 2,
        estimatedMinutes: 45,
        isActive: true,
        isPublished: true,
        fillsMadrigalGap: false,
        madrigalGapType: nil,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let mockLessons: [RoadmapLesson] = [
        mock,
        RoadmapLesson(
            id: "770e8400-e29b-41d4-a716-446655440001",
            roadmapId: Roadmap.mockSpanishRoadmap.id,
            curriculumGroupId: nil,
            lessonNumber: 2,
            title: "Present Tense Verbs",
            subtitle: "Master the present tense",
            description: "Learn regular -ar, -er, and -ir verb conjugations in the present tense.",
            cefrLevel: .a1,
            category: .grammar,
            lessonType: .verbConjugation,
            difficulty: 3,
            estimatedMinutes: 60,
            isActive: true,
            isPublished: true,
            fillsMadrigalGap: false,
            madrigalGapType: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}
*/
