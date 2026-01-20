//
//  CurriculumGroup.swift
//  LanguageLuid
//
//  Curriculum group model matching backend API
//

import Foundation

// MARK: - Group Type Enum

enum GroupType: String, Codable, CaseIterable {
    case cognateTier = "cognate_tier"
    case verbFormation = "verb_formation"
    case pastTense = "past_tense"
    case timeExpressions = "time_expressions"
    case survival
    case futureTense = "future_tense"
    case naturalExpressions = "natural_expressions"
    case practicalCommunication = "practical_communication"
    case grammarRefinement = "grammar_refinement"
    case subjunctiveMood = "subjunctive_mood"
    case advancedCommunication = "advanced_communication"
    case grammarMastery = "grammar_mastery"
    case advancedGrammar = "advanced_grammar"
    case advancedSubjunctive = "advanced_subjunctive"
    case complexGrammar = "complex_grammar"
    case professional
    case nuancedCommunication = "nuanced_communication"
    case regionalVarieties = "regional_varieties"
    case literaryMedia = "literary_media"
    case nearNative = "near_native"
    case idiomaticMastery = "idiomatic_mastery"
    case academicProfessional = "academic_professional"
    case culturalDeepDives = "cultural_deep_dives"
    case dialectalVariations = "dialectal_variations"
    case creativeExpression = "creative_expression"
    case mastery
    case assessment
    case review
    case custom

    var displayName: String {
        switch self {
        case .cognateTier:
            return "Cognate Tier"
        case .verbFormation:
            return "Verb Formation"
        case .pastTense:
            return "Past Tense"
        case .timeExpressions:
            return "Time Expressions"
        case .survival:
            return "Survival Phrases"
        case .futureTense:
            return "Future Tense"
        case .naturalExpressions:
            return "Natural Expressions"
        case .practicalCommunication:
            return "Practical Communication"
        case .grammarRefinement:
            return "Grammar Refinement"
        case .subjunctiveMood:
            return "Subjunctive Mood"
        case .advancedCommunication:
            return "Advanced Communication"
        case .grammarMastery:
            return "Grammar Mastery"
        case .advancedGrammar:
            return "Advanced Grammar"
        case .advancedSubjunctive:
            return "Advanced Subjunctive"
        case .complexGrammar:
            return "Complex Grammar"
        case .professional:
            return "Professional"
        case .nuancedCommunication:
            return "Nuanced Communication"
        case .regionalVarieties:
            return "Regional Varieties"
        case .literaryMedia:
            return "Literary & Media"
        case .nearNative:
            return "Near-Native Fluency"
        case .idiomaticMastery:
            return "Idiomatic Mastery"
        case .academicProfessional:
            return "Academic & Professional"
        case .culturalDeepDives:
            return "Cultural Deep Dives"
        case .dialectalVariations:
            return "Dialectal Variations"
        case .creativeExpression:
            return "Creative Expression"
        case .mastery:
            return "Mastery"
        case .assessment:
            return "Assessment"
        case .review:
            return "Review"
        case .custom:
            return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .cognateTier:
            return "link"
        case .verbFormation:
            return "arrow.triangle.2.circlepath"
        case .pastTense:
            return "clock.arrow.circlepath"
        case .timeExpressions:
            return "calendar"
        case .survival:
            return "lifepreserver"
        case .futureTense:
            return "arrow.forward.circle"
        case .naturalExpressions:
            return "bubble.left.and.bubble.right"
        case .practicalCommunication:
            return "message"
        case .grammarRefinement:
            return "textformat.alt"
        case .subjunctiveMood:
            return "questionmark.square"
        case .advancedCommunication:
            return "person.2"
        case .grammarMastery:
            return "graduationcap"
        case .advancedGrammar:
            return "book.closed"
        case .advancedSubjunctive:
            return "exclamationmark.square"
        case .complexGrammar:
            return "character.book.closed"
        case .professional:
            return "briefcase.fill"
        case .nuancedCommunication:
            return "bubble.left.and.text.bubble.right"
        case .regionalVarieties:
            return "globe.europe.africa"
        case .literaryMedia:
            return "text.book.closed"
        case .nearNative:
            return "sparkles"
        case .idiomaticMastery:
            return "quote.bubble"
        case .academicProfessional:
            return "briefcase"
        case .culturalDeepDives:
            return "theatermasks"
        case .dialectalVariations:
            return "waveform"
        case .creativeExpression:
            return "pencil.and.outline"
        case .mastery:
            return "star.fill"
        case .assessment:
            return "checkmark.seal"
        case .review:
            return "arrow.clockwise"
        case .custom:
            return "circle"
        }
    }
}

// MARK: - Impact Level Enum

enum ImpactLevel: String, Codable {
    case low
    case medium
    case mediumHigh = "medium_high"
    case high
    case critical

    var displayName: String {
        switch self {
        case .low:
            return "Low Impact"
        case .medium:
            return "Medium Impact"
        case .mediumHigh:
            return "Medium-High Impact"
        case .high:
            return "High Impact"
        case .critical:
            return "Critical Impact"
        }
    }

    var color: String {
        switch self {
        case .low:
            return "gray"
        case .medium:
            return "blue"
        case .mediumHigh:
            return "orange"
        case .high:
            return "red"
        case .critical:
            return "purple"
        }
    }

    var priority: Int {
        switch self {
        case .low:
            return 1
        case .medium:
            return 2
        case .mediumHigh:
            return 3
        case .high:
            return 4
        case .critical:
            return 5
        }
    }
}

// MARK: - Curriculum Group Model

struct CurriculumGroup: Codable, Identifiable, Hashable {
    let id: String
    let roadmapId: String
    let name: String
    let slug: String
    let description: String?
    let cefrLevel: CEFRLevel
    let cefrLevelSecondary: CEFRLevel?
    let groupType: GroupType
    let displayOrder: Int
    let lessonStartNumber: Int
    let lessonEndNumber: Int
    let totalLessons: Int
    let estimatedMinutes: Int?
    let priority: Int
    let impactLevel: ImpactLevel
    let fillsMadrigalGap: Bool
    let madrigalGapDescription: String?
    let objectives: [String]
    let prerequisites: [String]?
    let unlockConditions: [String: AnyCodable]?
    let isActive: Bool
    let iconName: String?
    let colorHex: String?
    let metadata: [String: AnyCodable]?
    let createdAt: Date
    let updatedAt: Date

    // Optional relationships
    let roadmap: Roadmap?
    let lessons: [RoadmapLesson]?

    enum CodingKeys: String, CodingKey {
        case id, roadmapId, name, slug, description
        case cefrLevel, cefrLevelSecondary, groupType, displayOrder
        case lessonStartNumber, lessonEndNumber, totalLessons
        case estimatedMinutes, priority, impactLevel
        case fillsMadrigalGap, madrigalGapDescription, objectives
        case prerequisites, unlockConditions, isActive
        case iconName, colorHex, metadata, createdAt, updatedAt
        case roadmap, lessons
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CurriculumGroup, rhs: CurriculumGroup) -> Bool {
        lhs.id == rhs.id
    }

    // Computed properties
    var lessonCount: Int {
        totalLessons
    }

    var completedLessonCount: Int {
        // This will be calculated from user progress
        0
    }

    var progressPercentage: Double {
        guard totalLessons > 0 else { return 0 }
        return (Double(completedLessonCount) / Double(totalLessons)) * 100
    }

    var cefrDisplay: String {
        if let secondary = cefrLevelSecondary {
            return "\(cefrLevel.rawValue)-\(secondary.rawValue)"
        }
        return cefrLevel.rawValue
    }

    var lessonRangeDisplay: String {
        if lessonStartNumber == lessonEndNumber {
            return "L\(lessonStartNumber)"
        }
        return "L\(lessonStartNumber)-L\(lessonEndNumber)"
    }

    var estimatedHours: Double? {
        guard let minutes = estimatedMinutes else { return nil }
        return Double(minutes) / 60.0
    }

    var estimatedTimeFormatted: String {
        guard let minutes = estimatedMinutes else { return "N/A" }
        if minutes >= 60 {
            let hours = Double(minutes) / 60.0
            return String(format: "%.1f hours", hours)
        }
        return "\(minutes) minutes"
    }

    var displayIcon: String {
        iconName ?? groupType.icon
    }

    var hasMadrigalGap: Bool {
        fillsMadrigalGap
    }

    var isCompleted: Bool {
        completedLessonCount >= totalLessons
    }

    var isInProgress: Bool {
        completedLessonCount > 0 && completedLessonCount < totalLessons
    }

    var isLocked: Bool {
        // This will be determined by prerequisites check
        false
    }
}

// MARK: - Group Progress (User-specific)

struct CurriculumGroupProgress: Codable {
    let groupId: String
    let totalLessons: Int
    let completed: Int
    let inProgress: Int
    let notStarted: Int
    let completionPercentage: Double
    let averageScore: Double

    var isCompleted: Bool {
        completed >= totalLessons
    }

    var isInProgress: Bool {
        inProgress > 0 || (completed > 0 && completed < totalLessons)
    }
}

// MARK: - Mock Data for Previews
// TODO: Fix mock data - references unavailable Roadmap.mockSpanishRoadmap
/*
extension CurriculumGroup {
    static let mockCognateTier1 = CurriculumGroup(
        id: "880e8400-e29b-41d4-a716-446655440000",
        roadmapId: Roadmap.mockSpanishRoadmap.id,
        name: "Cognate Tier 1",
        slug: "cognate-tier-1",
        description: "Learn 1000+ Spanish words through English-Spanish cognates. Perfect start for beginners.",
        cefrLevel: .a1,
        cefrLevelSecondary: nil,
        groupType: .cognateTier,
        displayOrder: 1,
        lessonStartNumber: 1,
        lessonEndNumber: 5,
        totalLessons: 5,
        estimatedMinutes: 225,
        priority: 10,
        impactLevel: .critical,
        fillsMadrigalGap: false,
        madrigalGapDescription: nil,
        objectives: [
            "Recognize 1000+ Spanish cognates",
            "Build confidence with instant vocabulary",
            "Understand cognate patterns and rules"
        ],
        prerequisites: nil,
        unlockConditions: nil,
        isActive: true,
        iconName: "link",
        colorHex: "#4CAF50",
        metadata: nil,
        createdAt: Date(),
        updatedAt: Date(),
        roadmap: nil,
        lessons: nil
    )

    static let mockVerbFormation = CurriculumGroup(
        id: "880e8400-e29b-41d4-a716-446655440001",
        roadmapId: Roadmap.mockSpanishRoadmap.id,
        name: "Verb Formation Basics",
        slug: "verb-formation-basics",
        description: "Master present tense conjugations for regular -ar, -er, and -ir verbs.",
        cefrLevel: .a1,
        cefrLevelSecondary: .a2,
        groupType: .verbFormation,
        displayOrder: 2,
        lessonStartNumber: 6,
        lessonEndNumber: 12,
        totalLessons: 7,
        estimatedMinutes: 420,
        priority: 9,
        impactLevel: .critical,
        fillsMadrigalGap: false,
        madrigalGapDescription: nil,
        objectives: [
            "Conjugate regular -ar verbs in present tense",
            "Conjugate regular -er verbs in present tense",
            "Conjugate regular -ir verbs in present tense",
            "Understand verb endings and patterns"
        ],
        prerequisites: ["880e8400-e29b-41d4-a716-446655440000"],
        unlockConditions: nil,
        isActive: true,
        iconName: "arrow.triangle.2.circlepath",
        colorHex: "#2196F3",
        metadata: nil,
        createdAt: Date(),
        updatedAt: Date(),
        roadmap: nil,
        lessons: nil
    )

    static let mockSurvivalSpanish = CurriculumGroup(
        id: "880e8400-e29b-41d4-a716-446655440002",
        roadmapId: Roadmap.mockSpanishRoadmap.id,
        name: "Survival Spanish",
        slug: "survival-spanish",
        description: "Essential phrases and expressions for real-world communication. Fills Madrigal gap in practical conversation.",
        cefrLevel: .a2,
        cefrLevelSecondary: nil,
        groupType: .survival,
        displayOrder: 5,
        lessonStartNumber: 25,
        lessonEndNumber: 32,
        totalLessons: 8,
        estimatedMinutes: 480,
        priority: 8,
        impactLevel: .high,
        fillsMadrigalGap: true,
        madrigalGapDescription: "Madrigal focuses on written patterns but lacks practical survival phrases. This group fills that gap with essential real-world communication.",
        objectives: [
            "Handle basic travel situations",
            "Order food and drinks",
            "Ask for directions",
            "Make basic purchases",
            "Handle emergencies"
        ],
        prerequisites: ["880e8400-e29b-41d4-a716-446655440000", "880e8400-e29b-41d4-a716-446655440001"],
        unlockConditions: nil,
        isActive: true,
        iconName: "lifepreserver",
        colorHex: "#FF9800",
        metadata: nil,
        createdAt: Date(),
        updatedAt: Date(),
        roadmap: nil,
        lessons: nil
    )

    static let mockGroups = [
        mockCognateTier1,
        mockVerbFormation,
        mockSurvivalSpanish
    ]
}

extension CurriculumGroupProgress {
    static let mock = CurriculumGroupProgress(
        groupId: CurriculumGroup.mockCognateTier1.id,
        totalLessons: 5,
        completed: 3,
        inProgress: 1,
        notStarted: 1,
        completionPercentage: 60.0,
        averageScore: 0.85
    )
}
*/
