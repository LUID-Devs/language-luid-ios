//
//  LessonPhase.swift
//  LanguageLuid
//
//  Lesson phase models for 4-phase lesson structure
//  Matches backend phase progress API
//

import Foundation

// MARK: - Lesson Phase Definition

struct LessonPhaseDefinition: Codable, Identifiable, Hashable {
    let id: String
    let lessonId: String
    let phaseNumber: Int
    let phaseName: String
    let phaseType: PhaseType
    let description: String?
    let instructions: String?
    let estimatedMinutes: Int
    let pointsValue: Int
    let requiredScore: Double
    let exerciseCount: Int?
    let displayOrder: Int
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date

    // Optional relationships
    let exercises: [Exercise]?

    enum CodingKeys: String, CodingKey {
        case id, lessonId, phaseNumber, phaseName, phaseType
        case description, instructions, estimatedMinutes, pointsValue
        case requiredScore, exerciseCount, displayOrder, isActive
        case createdAt, updatedAt, exercises
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: LessonPhaseDefinition, rhs: LessonPhaseDefinition) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Computed Properties

    var displayName: String {
        "Phase \(phaseNumber): \(phaseName)"
    }

    var icon: String {
        phaseType.icon
    }

    var requiredScorePercentage: Int {
        Int(requiredScore * 100)
    }

    var estimatedDurationFormatted: String {
        "\(estimatedMinutes) min"
    }

    var isPatternRecognition: Bool {
        phaseType == .patternRecognition
    }

    var isSentenceBuilding: Bool {
        phaseType == .sentenceBuilding
    }

    var isTranslationChallenge: Bool {
        phaseType == .translationChallenge
    }

    var isConversationPractice: Bool {
        phaseType == .conversationPractice
    }
}

// MARK: - Phase Type Enum

enum PhaseType: String, Codable {
    case patternRecognition = "pattern_recognition"
    case sentenceBuilding = "sentence_building"
    case translationChallenge = "translation_challenge"
    case conversationPractice = "conversation_practice"
    case listeningComprehension = "listening_comprehension"
    case speaking = "speaking"
    case review = "review"
    case assessment = "assessment"

    var displayName: String {
        switch self {
        case .patternRecognition:
            return "Pattern Recognition"
        case .sentenceBuilding:
            return "Sentence Building"
        case .translationChallenge:
            return "Translation Challenge"
        case .conversationPractice:
            return "Conversation Practice"
        case .listeningComprehension:
            return "Listening Comprehension"
        case .speaking:
            return "Speaking"
        case .review:
            return "Review"
        case .assessment:
            return "Assessment"
        }
    }

    var icon: String {
        switch self {
        case .patternRecognition:
            return "lightbulb.fill"
        case .sentenceBuilding:
            return "square.stack.3d.up.fill"
        case .translationChallenge:
            return "arrow.left.arrow.right"
        case .conversationPractice:
            return "bubble.left.and.bubble.right.fill"
        case .listeningComprehension:
            return "ear.fill"
        case .speaking:
            return "waveform"
        case .review:
            return "arrow.clockwise"
        case .assessment:
            return "checkmark.seal.fill"
        }
    }

    var description: String {
        switch self {
        case .patternRecognition:
            return "Learn to recognize patterns and structures"
        case .sentenceBuilding:
            return "Practice building sentences from patterns"
        case .translationChallenge:
            return "Test your translation skills"
        case .conversationPractice:
            return "Practice real conversations"
        case .listeningComprehension:
            return "Improve listening skills"
        case .speaking:
            return "Practice pronunciation and speaking"
        case .review:
            return "Review and reinforce learning"
        case .assessment:
            return "Evaluate your progress"
        }
    }
}

// MARK: - Lesson Phase Progress

struct LessonPhaseProgress: Codable, Identifiable, Hashable {
    let id: String
    let userId: String
    let lessonId: String
    let phaseNumber: Int
    let status: PhaseStatus
    let score: Double?
    let maxScore: Double?
    let timeSpent: Int?
    let completed: Bool
    let completedAt: Date?
    let currentStep: Int?
    let totalSteps: Int?
    let completedSteps: [Int]?
    let stepScores: [String: Double]?
    let attempts: Int
    let lastAttemptAt: Date?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, userId, lessonId, phaseNumber, status
        case score, maxScore, timeSpent, completed, completedAt
        case currentStep, totalSteps, completedSteps, stepScores
        case attempts, lastAttemptAt, createdAt, updatedAt
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: LessonPhaseProgress, rhs: LessonPhaseProgress) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Computed Properties

    var scorePercentage: Int {
        guard let score = score, let maxScore = maxScore, maxScore > 0 else {
            return 0
        }
        return Int((score / maxScore) * 100)
    }

    var progressPercentage: Double {
        guard let current = currentStep, let total = totalSteps, total > 0 else {
            return 0
        }
        return (Double(current) / Double(total)) * 100
    }

    var timeSpentFormatted: String {
        guard let time = timeSpent else { return "0s" }
        let minutes = time / 60
        let seconds = time % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }

    var isLocked: Bool {
        status == .locked
    }

    var isAvailable: Bool {
        status == .available || status == .inProgress
    }

    var isPassed: Bool {
        completed && (score ?? 0) >= (maxScore ?? 1) * 0.7
    }

    var needsRetry: Bool {
        !completed || !isPassed
    }
}

// MARK: - Phase Status Enum

enum PhaseStatus: String, Codable {
    case locked
    case available
    case inProgress = "in_progress"
    case completed

    var displayName: String {
        switch self {
        case .locked:
            return "Locked"
        case .available:
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
        case .available:
            return "play.circle"
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
        case .available:
            return "blue"
        case .inProgress:
            return "orange"
        case .completed:
            return "green"
        }
    }
}

// MARK: - Phase Progress Summary

struct PhaseProgressSummary: Codable {
    let lessonId: String
    let currentPhase: Int
    let phaseStates: [PhaseState]
    let progressPercentage: Double
    let isLessonCompleted: Bool
    let isAuthenticated: Bool

    enum CodingKeys: String, CodingKey {
        case lessonId, currentPhase, phaseStates
        case progressPercentage, isLessonCompleted, isAuthenticated
    }

    var totalPhases: Int {
        phaseStates.count
    }

    var completedPhases: Int {
        phaseStates.filter { $0.completed }.count
    }

    var currentPhaseState: PhaseState? {
        phaseStates.first { $0.phase == currentPhase }
    }

    var nextPhase: Int? {
        guard currentPhase < totalPhases else { return nil }
        return currentPhase + 1
    }

    var canProgress: Bool {
        guard let current = currentPhaseState else { return false }
        return current.completed && !isLessonCompleted
    }
}

// MARK: - Phase State

struct PhaseState: Codable, Identifiable {
    let phase: Int
    let status: PhaseStatus
    let score: Double?
    let completed: Bool

    var id: Int { phase }

    enum CodingKeys: String, CodingKey {
        case phase, status, score, completed
    }

    var scorePercentage: Int {
        guard let score = score else { return 0 }
        return Int(score * 100)
    }

    var isPassed: Bool {
        completed && (score ?? 0) >= 0.7
    }
}

// MARK: - Mock Data for Previews
// TODO: Re-enable after fixing Lesson mock data
/*
extension LessonPhaseDefinition {
    static let mockPhase1 = LessonPhaseDefinition(
        id: "phase-1",
        lessonId: Lesson.mock.id,
        phaseNumber: 1,
        phaseName: "Pattern Recognition",
        phaseType: .patternRecognition,
        description: "Learn to recognize cognate patterns",
        instructions: "Identify words that follow the -ous → -oso pattern",
        estimatedMinutes: 10,
        pointsValue: 25,
        requiredScore: 0.7,
        exerciseCount: 8,
        displayOrder: 1,
        isActive: true,
        createdAt: Date(),
        updatedAt: Date(),
        exercises: nil
    )

    static let mockPhase2 = LessonPhaseDefinition(
        id: "phase-2",
        lessonId: Lesson.mock.id,
        phaseNumber: 2,
        phaseName: "Sentence Building",
        phaseType: .sentenceBuilding,
        description: "Build sentences using cognates",
        instructions: "Construct sentences with the patterns you learned",
        estimatedMinutes: 15,
        pointsValue: 30,
        requiredScore: 0.7,
        exerciseCount: 10,
        displayOrder: 2,
        isActive: true,
        createdAt: Date(),
        updatedAt: Date(),
        exercises: nil
    )

    static let mockPhase3 = LessonPhaseDefinition(
        id: "phase-3",
        lessonId: Lesson.mock.id,
        phaseNumber: 3,
        phaseName: "Translation Challenge",
        phaseType: .translationChallenge,
        description: "Translate sentences using cognates",
        instructions: "Translate between English and Spanish",
        estimatedMinutes: 12,
        pointsValue: 35,
        requiredScore: 0.7,
        exerciseCount: 12,
        displayOrder: 3,
        isActive: true,
        createdAt: Date(),
        updatedAt: Date(),
        exercises: nil
    )

    static let mockPhase4 = LessonPhaseDefinition(
        id: "phase-4",
        lessonId: Lesson.mock.id,
        phaseNumber: 4,
        phaseName: "Conversation Practice",
        phaseType: .conversationPractice,
        description: "Practice in conversation context",
        instructions: "Use cognates in realistic conversations",
        estimatedMinutes: 8,
        pointsValue: 10,
        requiredScore: 0.7,
        exerciseCount: 5,
        displayOrder: 4,
        isActive: true,
        createdAt: Date(),
        updatedAt: Date(),
        exercises: nil
    )

    static let mockPhases = [mockPhase1, mockPhase2, mockPhase3, mockPhase4]
}

extension LessonPhaseProgress {
    static let mockProgress = LessonPhaseProgress(
        id: "progress-1",
        userId: "user-123",
        lessonId: Lesson.mock.id,
        phaseNumber: 1,
        status: .completed,
        score: 0.85,
        maxScore: 1.0,
        timeSpent: 480,
        completed: true,
        completedAt: Date(),
        currentStep: 8,
        totalSteps: 8,
        completedSteps: [0, 1, 2, 3, 4, 5, 6, 7],
        stepScores: ["0": 1.0, "1": 0.8, "2": 0.9],
        attempts: 1,
        lastAttemptAt: Date(),
        createdAt: Date(),
        updatedAt: Date()
    )
}

extension PhaseProgressSummary {
    static let mock = PhaseProgressSummary(
        lessonId: Lesson.mock.id,
        currentPhase: 2,
        phaseStates: [
            PhaseState(phase: 1, status: .completed, score: 0.85, completed: true),
            PhaseState(phase: 2, status: .inProgress, score: 0.4, completed: false),
            PhaseState(phase: 3, status: .locked, score: nil, completed: false),
            PhaseState(phase: 4, status: .locked, score: nil, completed: false)
        ],
        progressPercentage: 25,
        isLessonCompleted: false,
        isAuthenticated: true
    )
}
*/
