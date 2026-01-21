//
//  Lesson.swift
//  LanguageLuid
//
//  Comprehensive lesson model matching backend API structure
//  Supports roadmap-based lessons with phases, exercises, and progress tracking
//

import Foundation

// MARK: - Lesson Model

struct Lesson: Codable, Identifiable, Hashable {
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
    let pointsValue: Int?
    let vocabulary: [VocabularyItem]?
    let grammarPoints: [String]?
    let phrases: [PhraseItem]?
    let hasSpeechExercises: Bool
    let hasAIConversation: Bool
    let prerequisites: [String]?
    let learningObjectives: [String]?
    let isActive: Bool
    let isPublished: Bool
    let publishedAt: Date?
    let fillsMadrigalGap: Bool
    let madrigalGapType: String?
    let createdAt: Date
    let updatedAt: Date

    // Optional relationships (populated by specific endpoints)
    let phases: [LessonPhaseDefinition]?
    let exercises: [Exercise]?
    let userProgress: UserLessonProgress?

    enum CodingKeys: String, CodingKey {
        case id, roadmapId, curriculumGroupId, lessonNumber
        case title, subtitle, description, cefrLevel, category, lessonType
        case difficulty, estimatedMinutes, pointsValue
        case vocabulary, grammarPoints, phrases
        case hasSpeechExercises, hasAIConversation, prerequisites, learningObjectives
        case isActive, isPublished, publishedAt
        case fillsMadrigalGap, madrigalGapType, createdAt, updatedAt
        case phases, exercises, userProgress
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Lesson, rhs: Lesson) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Computed Properties

    var lessonNumberFormatted: String {
        "L\(lessonNumber)"
    }

    var displayTitle: String {
        "\(lessonNumberFormatted): \(title)"
    }

    var estimatedDurationFormatted: String {
        if estimatedMinutes >= 60 {
            let hours = estimatedMinutes / 60
            let minutes = estimatedMinutes % 60
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else {
            return "\(estimatedMinutes) min"
        }
    }

    var difficultyLevel: String {
        switch difficulty {
        case 1...2:
            return "Easy"
        case 3...4:
            return "Beginner"
        case 5...6:
            return "Intermediate"
        case 7...8:
            return "Advanced"
        case 9...10:
            return "Expert"
        default:
            return "Unknown"
        }
    }

    var difficultyStars: String {
        String(repeating: "⭐", count: min(difficulty, 10))
    }

    var status: LessonStatus {
        if let progress = userProgress {
            return progress.status
        }
        return .locked
    }

    var isLocked: Bool {
        status == .locked
    }

    var isCompleted: Bool {
        status == .completed
    }

    var isInProgress: Bool {
        status == .inProgress
    }

    var vocabularyCount: Int {
        vocabulary?.count ?? 0
    }

    var grammarPointsCount: Int {
        grammarPoints?.count ?? 0
    }

    var phrasesCount: Int {
        phrases?.count ?? 0
    }

    var hasPrerequisites: Bool {
        !(prerequisites?.isEmpty ?? true)
    }

    var canStart: Bool {
        !isLocked && (isPublished || AppConfig.isDevelopment)
    }
}

// MARK: - Lesson Status Enum

enum LessonStatus: String, Codable {
    case locked
    case available
    case notStarted = "not_started"  // Backend returns this for lessons without progress
    case inProgress = "in_progress"
    case completed

    var displayName: String {
        switch self {
        case .locked:
            return "Locked"
        case .available, .notStarted:
            return "Available"
        case .inProgress:
            return "In Progress"
        case .completed:
            return "Completed"
        }
    }

    var icon: String {
        switch self {
        case .locked:
            return "lock.fill"
        case .available, .notStarted:
            return "circle"
        case .inProgress:
            return "circle.lefthalf.filled"
        case .completed:
            return "checkmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .locked:
            return "gray"
        case .available, .notStarted:
            return "blue"
        case .inProgress:
            return "orange"
        case .completed:
            return "green"
        }
    }
}

// MARK: - Vocabulary Item

struct VocabularyItem: Codable, Identifiable, Hashable {
    let id: String
    let word: String
    let translation: String
    let pronunciation: String?
    let audioUrl: String?
    let partOfSpeech: String?
    let gender: String?
    let exampleSentence: String?
    let exampleTranslation: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, word, translation, pronunciation, audioUrl
        case partOfSpeech, gender, exampleSentence, exampleTranslation, notes
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: VocabularyItem, rhs: VocabularyItem) -> Bool {
        lhs.id == rhs.id
    }

    var displayWord: String {
        if let gender = gender, !gender.isEmpty {
            return "\(gender) \(word)"
        }
        return word
    }
}

// MARK: - Phrase Item

struct PhraseItem: Codable, Identifiable, Hashable {
    let id: String
    let phrase: String
    let translation: String
    let pronunciation: String?
    let audioUrl: String?
    let usageContext: String?
    let formality: String?
    let alternativePhrases: [String]?

    enum CodingKeys: String, CodingKey {
        case id, phrase, translation, pronunciation, audioUrl
        case usageContext, formality, alternativePhrases
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PhraseItem, rhs: PhraseItem) -> Bool {
        lhs.id == rhs.id
    }

    var formalityLevel: String {
        switch formality?.lowercased() {
        case "formal":
            return "Formal"
        case "informal":
            return "Informal"
        case "neutral":
            return "Neutral"
        default:
            return "General"
        }
    }
}

// MARK: - Mock Data for Previews
// TODO: Re-enable after fixing Roadmap mock data
/*
extension Lesson {
    static let mock = Lesson(
        id: "880e8400-e29b-41d4-a716-446655440000",
        roadmapId: Roadmap.mockSpanishRoadmap.id,
        curriculumGroupId: "990e8400-e29b-41d4-a716-446655440000",
        lessonNumber: 1,
        title: "Spanish Cognates - 1000 Words",
        subtitle: "Learn 1000+ Spanish words you already know",
        description: "Discover how many Spanish words you can instantly recognize through English-Spanish cognates. This lesson uses the Madrigal method to build your vocabulary rapidly.",
        cefrLevel: .a1,
        category: .vocabulary,
        lessonType: .cognate,
        difficulty: 2,
        estimatedMinutes: 45,
        pointsValue: 100,
        vocabulary: [
            VocabularyItem(
                id: "v1",
                word: "famoso",
                translation: "famous",
                pronunciation: "fah-MOH-soh",
                audioUrl: nil,
                partOfSpeech: "adjective",
                gender: nil,
                exampleSentence: "Es un actor famoso.",
                exampleTranslation: "He is a famous actor.",
                notes: "Direct cognate"
            ),
            VocabularyItem(
                id: "v2",
                word: "importante",
                translation: "important",
                pronunciation: "eem-por-TAHN-teh",
                audioUrl: nil,
                partOfSpeech: "adjective",
                gender: nil,
                exampleSentence: "Es muy importante.",
                exampleTranslation: "It is very important.",
                notes: "Direct cognate"
            )
        ],
        grammarPoints: [
            "Cognate patterns: -ous → -oso",
            "Cognate patterns: -ant/-ent → -ante/-ente",
            "Gender agreement with adjectives"
        ],
        phrases: [
            PhraseItem(
                id: "p1",
                phrase: "Es muy famoso",
                translation: "It is very famous",
                pronunciation: "ess moo-ee fah-MOH-soh",
                audioUrl: nil,
                usageContext: "Describing something well-known",
                formality: "neutral",
                alternativePhrases: ["Es conocido", "Es reconocido"]
            )
        ],
        hasSpeechExercises: true,
        hasAIConversation: false,
        prerequisites: nil,
        learningObjectives: [
            "Recognize 1000+ Spanish cognates",
            "Understand cognate patterns",
            "Build instant vocabulary recognition"
        ],
        isActive: true,
        isPublished: true,
        publishedAt: Date(),
        fillsMadrigalGap: false,
        madrigalGapType: nil,
        createdAt: Date(),
        updatedAt: Date(),
        phases: nil,
        exercises: nil,
        userProgress: nil
    )

    static let mockLessons: [Lesson] = [
        mock,
        Lesson(
            id: "880e8400-e29b-41d4-a716-446655440001",
            roadmapId: Roadmap.mockSpanishRoadmap.id,
            curriculumGroupId: "990e8400-e29b-41d4-a716-446655440000",
            lessonNumber: 2,
            title: "Present Tense Verbs",
            subtitle: "Master the present tense",
            description: "Learn regular -ar, -er, and -ir verb conjugations in the present tense.",
            cefrLevel: .a1,
            category: .grammar,
            lessonType: .verbConjugation,
            difficulty: 4,
            estimatedMinutes: 60,
            pointsValue: 150,
            vocabulary: nil,
            grammarPoints: [
                "-ar verb conjugation",
                "-er verb conjugation",
                "-ir verb conjugation"
            ],
            phrases: nil,
            hasSpeechExercises: true,
            hasAIConversation: true,
            prerequisites: ["880e8400-e29b-41d4-a716-446655440000"],
            learningObjectives: [
                "Conjugate regular -ar verbs",
                "Conjugate regular -er verbs",
                "Conjugate regular -ir verbs"
            ],
            isActive: true,
            isPublished: true,
            publishedAt: Date(),
            fillsMadrigalGap: false,
            madrigalGapType: nil,
            createdAt: Date(),
            updatedAt: Date(),
            phases: nil,
            exercises: nil,
            userProgress: nil
        ),
        Lesson(
            id: "880e8400-e29b-41d4-a716-446655440002",
            roadmapId: Roadmap.mockSpanishRoadmap.id,
            curriculumGroupId: "990e8400-e29b-41d4-a716-446655440001",
            lessonNumber: 3,
            title: "Basic Conversation",
            subtitle: "Essential greetings and introductions",
            description: "Learn how to introduce yourself and have basic conversations in Spanish.",
            cefrLevel: .a1,
            category: .conversation,
            lessonType: .conversationPractice,
            difficulty: 3,
            estimatedMinutes: 40,
            pointsValue: 120,
            vocabulary: nil,
            grammarPoints: nil,
            phrases: [
                PhraseItem(
                    id: "p3-1",
                    phrase: "Hola, ¿cómo estás?",
                    translation: "Hello, how are you?",
                    pronunciation: "OH-lah, KOH-moh es-TAHS",
                    audioUrl: nil,
                    usageContext: "Informal greeting",
                    formality: "informal",
                    alternativePhrases: ["¿Qué tal?", "¿Cómo te va?"]
                )
            ],
            hasSpeechExercises: true,
            hasAIConversation: true,
            prerequisites: nil,
            learningObjectives: [
                "Greet people appropriately",
                "Introduce yourself",
                "Ask basic questions"
            ],
            isActive: true,
            isPublished: true,
            publishedAt: Date(),
            fillsMadrigalGap: false,
            madrigalGapType: nil,
            createdAt: Date(),
            updatedAt: Date(),
            phases: nil,
            exercises: nil,
            userProgress: nil
        )
    ]
}
*/

extension VocabularyItem {
    static let mockItems: [VocabularyItem] = [
        VocabularyItem(
            id: "v1",
            word: "famoso",
            translation: "famous",
            pronunciation: "fah-MOH-soh",
            audioUrl: nil,
            partOfSpeech: "adjective",
            gender: nil,
            exampleSentence: "Es un actor famoso.",
            exampleTranslation: "He is a famous actor.",
            notes: "Direct cognate"
        ),
        VocabularyItem(
            id: "v2",
            word: "importante",
            translation: "important",
            pronunciation: "eem-por-TAHN-teh",
            audioUrl: nil,
            partOfSpeech: "adjective",
            gender: nil,
            exampleSentence: "Es muy importante.",
            exampleTranslation: "It is very important.",
            notes: "Direct cognate"
        ),
        VocabularyItem(
            id: "v3",
            word: "casa",
            translation: "house",
            pronunciation: "KAH-sah",
            audioUrl: nil,
            partOfSpeech: "noun",
            gender: "la",
            exampleSentence: "Mi casa es grande.",
            exampleTranslation: "My house is big.",
            notes: "Feminine noun"
        )
    ]
}

extension PhraseItem {
    static let mockItems: [PhraseItem] = [
        PhraseItem(
            id: "p1",
            phrase: "¿Cómo estás?",
            translation: "How are you?",
            pronunciation: "KOH-moh es-TAHS",
            audioUrl: nil,
            usageContext: "Informal greeting",
            formality: "informal",
            alternativePhrases: ["¿Qué tal?", "¿Cómo te va?"]
        ),
        PhraseItem(
            id: "p2",
            phrase: "Mucho gusto",
            translation: "Nice to meet you",
            pronunciation: "MOO-choh GOO-stoh",
            audioUrl: nil,
            usageContext: "When meeting someone",
            formality: "neutral",
            alternativePhrases: ["Encantado/a", "Es un placer"]
        )
    ]
}
