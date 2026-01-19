//
//  Progress.swift
//  LanguageLuid
//
//  User progress tracking models for lessons and roadmaps
//  Matches backend progress APIs
//

import Foundation

// MARK: - User Lesson Progress

struct UserLessonProgress: Codable, Identifiable, Hashable {
    let id: String
    let userId: String
    let lessonId: String
    let roadmapId: String?
    let status: LessonStatus
    let currentPhase: Int
    let completedPhases: [Int]?
    let phaseScores: [String: Double]?
    let totalScore: Double?
    let maxScore: Double?
    let timeSpent: Int?
    let exercisesCompleted: Int?
    let totalExercises: Int?
    let accuracy: Double?
    let consecutiveDays: Int?
    let lastPhaseCompleted: Int?
    let startedAt: Date
    let completedAt: Date?
    let lastAccessedAt: Date
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, userId, lessonId, roadmapId, status
        case currentPhase, completedPhases, phaseScores
        case totalScore, maxScore, timeSpent
        case exercisesCompleted, totalExercises, accuracy
        case consecutiveDays, lastPhaseCompleted
        case startedAt, completedAt, lastAccessedAt
        case createdAt, updatedAt
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: UserLessonProgress, rhs: UserLessonProgress) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Computed Properties

    var progressPercentage: Double {
        guard let exercises = totalExercises, exercises > 0,
              let completed = exercisesCompleted else {
            return 0
        }
        return (Double(completed) / Double(exercises)) * 100
    }

    var scorePercentage: Int {
        guard let score = totalScore, let max = maxScore, max > 0 else {
            return 0
        }
        return Int((score / max) * 100)
    }

    var accuracyPercentage: Int {
        guard let acc = accuracy else { return 0 }
        return Int(acc * 100)
    }

    var timeSpentFormatted: String {
        guard let time = timeSpent else { return "0m" }
        let hours = time / 3600
        let minutes = (time % 3600) / 60
        let seconds = time % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    var isCompleted: Bool {
        status == .completed
    }

    var isInProgress: Bool {
        status == .inProgress
    }

    var isLocked: Bool {
        status == .locked
    }

    var canResume: Bool {
        isInProgress && currentPhase > 0
    }

    var completedPhasesCount: Int {
        completedPhases?.count ?? 0
    }

    var nextPhase: Int? {
        guard !isCompleted else { return nil }
        return currentPhase + 1
    }

    var averagePhaseScore: Double {
        guard let scores = phaseScores, !scores.isEmpty else { return 0 }
        let sum = scores.values.reduce(0, +)
        return sum / Double(scores.count)
    }

    var averagePhaseScorePercentage: Int {
        Int(averagePhaseScore * 100)
    }

    var isPassed: Bool {
        isCompleted && scorePercentage >= 70
    }

    var needsRetry: Bool {
        isCompleted && !isPassed
    }

    var daysActive: Int {
        consecutiveDays ?? 0
    }

    var lastAccessed: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastAccessedAt, relativeTo: Date())
    }
}

// MARK: - Progress Stats

struct ProgressStats: Codable {
    let totalLessons: Int
    let completedLessons: Int
    let inProgressLessons: Int
    let averageScore: Double?
    let totalTimeSpent: Int
    let totalPoints: Int?
    let accuracyRate: Double?
    let completionRate: Double
    let streakDays: Int?
    let lessonsThisWeek: Int?
    let lessonsThisMonth: Int?
    let lastActivityDate: Date?

    enum CodingKeys: String, CodingKey {
        case totalLessons, completedLessons, inProgressLessons
        case averageScore, totalTimeSpent, totalPoints, accuracyRate
        case completionRate, streakDays
        case lessonsThisWeek, lessonsThisMonth, lastActivityDate
    }

    // MARK: - Computed Properties

    var averageScorePercentage: Int {
        guard let score = averageScore else { return 0 }
        return Int(score * 100)
    }

    var accuracyPercentage: Int {
        guard let accuracy = accuracyRate else { return 0 }
        return Int(accuracy * 100)
    }

    var completionPercentage: Int {
        Int(completionRate * 100)
    }

    var totalTimeFormatted: String {
        let hours = totalTimeSpent / 3600
        let minutes = (totalTimeSpent % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var pointsFormatted: String {
        guard let points = totalPoints else { return "0 pts" }
        if points >= 1000 {
            return String(format: "%.1fk pts", Double(points) / 1000)
        }
        return "\(points) pts"
    }

    var streak: Int {
        streakDays ?? 0
    }

    var isActiveThisWeek: Bool {
        (lessonsThisWeek ?? 0) > 0
    }

    var isActiveThisMonth: Bool {
        (lessonsThisMonth ?? 0) > 0
    }

    var lastActivity: String {
        guard let lastDate = lastActivityDate else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastDate, relativeTo: Date())
    }
}

// MARK: - Roadmap Progress

struct RoadmapProgress: Codable, Identifiable {
    let id: String
    let userId: String
    let roadmapId: String
    let enrolledAt: Date
    let regionalVariantId: String?
    let totalLessons: Int
    let completedLessons: Int
    let inProgressLessons: Int
    let currentLessonNumber: Int?
    let lastLessonCompletedNumber: Int?
    let totalTimeSpent: Int
    let totalPoints: Int
    let averageScore: Double?
    let completionPercentage: Double
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, userId, roadmapId, enrolledAt, regionalVariantId
        case totalLessons, completedLessons, inProgressLessons
        case currentLessonNumber, lastLessonCompletedNumber
        case totalTimeSpent, totalPoints, averageScore, completionPercentage
        case createdAt, updatedAt
    }

    // MARK: - Computed Properties

    var progressPercentage: Int {
        Int(completionPercentage * 100)
    }

    var averageScorePercentage: Int {
        guard let score = averageScore else { return 0 }
        return Int(score * 100)
    }

    var timeSpentFormatted: String {
        let hours = totalTimeSpent / 3600
        let minutes = (totalTimeSpent % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var pointsFormatted: String {
        if totalPoints >= 1000 {
            return String(format: "%.1fk", Double(totalPoints) / 1000)
        }
        return "\(totalPoints)"
    }

    var lessonsRemaining: Int {
        totalLessons - completedLessons
    }

    var isCompleted: Bool {
        completedLessons >= totalLessons
    }

    var hasStarted: Bool {
        completedLessons > 0 || inProgressLessons > 0
    }

    var nextLessonNumber: Int? {
        guard !isCompleted else { return nil }
        if let current = currentLessonNumber {
            return current
        }
        if let lastCompleted = lastLessonCompletedNumber {
            return lastCompleted + 1
        }
        return 1
    }
}

// MARK: - CEFR Level Progress

struct CEFRLevelProgress: Codable {
    let level: CEFRLevel
    let totalLessons: Int
    let completedLessons: Int
    let inProgressLessons: Int
    let completionPercentage: Double
    let averageScore: Double?
    let totalTimeSpent: Int

    enum CodingKeys: String, CodingKey {
        case level, totalLessons, completedLessons, inProgressLessons
        case completionPercentage, averageScore, totalTimeSpent
    }

    var progressPercentage: Int {
        Int(completionPercentage * 100)
    }

    var averageScorePercentage: Int {
        guard let score = averageScore else { return 0 }
        return Int(score * 100)
    }

    var isCompleted: Bool {
        completedLessons >= totalLessons
    }

    var isPerfect: Bool {
        isCompleted && averageScorePercentage >= 95
    }
}

// MARK: - Mock Data for Previews
// TODO: Fix mock data - references to Lesson.mock and Roadmap.mockSpanishRoadmap are unavailable
/*
extension UserLessonProgress {
    static let mock = UserLessonProgress(
        id: "progress-123",
        userId: "user-123",
        lessonId: Lesson.mock.id,
        roadmapId: Roadmap.mockSpanishRoadmap.id,
        status: .inProgress,
        currentPhase: 2,
        completedPhases: [1],
        phaseScores: ["1": 0.85, "2": 0.65],
        totalScore: 75,
        maxScore: 100,
        timeSpent: 1800,
        exercisesCompleted: 15,
        totalExercises: 35,
        accuracy: 0.82,
        consecutiveDays: 5,
        lastPhaseCompleted: 1,
        startedAt: Date().addingTimeInterval(-86400 * 5),
        completedAt: nil,
        lastAccessedAt: Date().addingTimeInterval(-3600),
        createdAt: Date().addingTimeInterval(-86400 * 5),
        updatedAt: Date().addingTimeInterval(-3600)
    )

    static let mockCompleted = UserLessonProgress(
        id: "progress-456",
        userId: "user-123",
        lessonId: "lesson-456",
        roadmapId: Roadmap.mockSpanishRoadmap.id,
        status: .completed,
        currentPhase: 4,
        completedPhases: [1, 2, 3, 4],
        phaseScores: ["1": 0.95, "2": 0.88, "3": 0.92, "4": 0.90],
        totalScore: 100,
        maxScore: 100,
        timeSpent: 2700,
        exercisesCompleted: 35,
        totalExercises: 35,
        accuracy: 0.91,
        consecutiveDays: 3,
        lastPhaseCompleted: 4,
        startedAt: Date().addingTimeInterval(-86400 * 3),
        completedAt: Date().addingTimeInterval(-86400),
        lastAccessedAt: Date().addingTimeInterval(-86400),
        createdAt: Date().addingTimeInterval(-86400 * 3),
        updatedAt: Date().addingTimeInterval(-86400)
    )
}

extension ProgressStats {
    static let mock = ProgressStats(
        totalLessons: 50,
        completedLessons: 12,
        inProgressLessons: 3,
        averageScore: 0.85,
        totalTimeSpent: 14400,
        totalPoints: 1250,
        accuracyRate: 0.82,
        completionRate: 0.24,
        streakDays: 7,
        lessonsThisWeek: 5,
        lessonsThisMonth: 18,
        lastActivityDate: Date().addingTimeInterval(-3600)
    )
}

extension RoadmapProgress {
    static let mock = RoadmapProgress(
        id: "roadmap-progress-1",
        userId: "user-123",
        roadmapId: Roadmap.mockSpanishRoadmap.id,
        enrolledAt: Date().addingTimeInterval(-86400 * 30),
        regionalVariantId: nil,
        totalLessons: 97,
        completedLessons: 12,
        inProgressLessons: 2,
        currentLessonNumber: 13,
        lastLessonCompletedNumber: 12,
        totalTimeSpent: 14400,
        totalPoints: 1250,
        averageScore: 0.85,
        completionPercentage: 0.124,
        createdAt: Date().addingTimeInterval(-86400 * 30),
        updatedAt: Date().addingTimeInterval(-3600)
    )
}

extension CEFRLevelProgress {
    static let mockA1 = CEFRLevelProgress(
        level: .a1,
        totalLessons: 20,
        completedLessons: 12,
        inProgressLessons: 2,
        completionPercentage: 0.6,
        averageScore: 0.85,
        totalTimeSpent: 7200
    )

    static let mockA2 = CEFRLevelProgress(
        level: .a2,
        totalLessons: 18,
        completedLessons: 0,
        inProgressLessons: 0,
        completionPercentage: 0.0,
        averageScore: nil,
        totalTimeSpent: 0
    )
}
*/
