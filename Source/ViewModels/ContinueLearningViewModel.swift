//
//  ContinueLearningViewModel.swift
//  LanguageLuid
//
//  ViewModel for Continue Learning hub
//  Manages cross-language progress, in-progress lessons, recent activity, and recommendations
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ContinueLearningViewModel: ObservableObject {
    // MARK: - Published Properties

    // Lessons
    @Published var inProgressLessons: [LessonWithRoadmap] = []
    @Published var recentlyCompletedLessons: [LessonWithRoadmap] = []
    @Published var recommendedLessons: [LessonWithRoadmap] = []

    // Roadmaps
    @Published var enrolledRoadmaps: [Roadmap] = []
    @Published var roadmapProgress: [String: RoadmapProgress] = [:]  // roadmapId -> progress

    // UI State
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - Private Properties

    private let languageService: LanguageService
    private let lessonService: LessonService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        languageService: LanguageService = .shared,
        lessonService: LessonService = .shared
    ) {
        self.languageService = languageService
        self.lessonService = lessonService
    }

    // MARK: - Data Loading

    /// Load all data for Continue Learning view
    func loadAllData() async {
        isLoading = true
        errorMessage = nil

        do {
            // First, fetch enrolled roadmaps
            await loadEnrolledRoadmaps()

            // Then fetch lessons and progress in parallel
            async let inProgressTask = loadInProgressLessons()
            async let recentTask = loadRecentlyCompletedLessons()
            async let recommendedTask = loadRecommendedLessons()
            async let progressTask = loadAllRoadmapProgress()

            // Wait for all to complete
            await inProgressTask
            await recentTask
            await recommendedTask
            await progressTask

        } catch {
            errorMessage = "Failed to load learning data: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    /// Refresh all data
    func refresh() async {
        isRefreshing = true
        await loadAllData()
        isRefreshing = false
    }

    // MARK: - Enrolled Roadmaps

    /// Load user's enrolled roadmaps
    private func loadEnrolledRoadmaps() async {
        do {
            // Fetch all roadmaps (user enrollment will be indicated by progress)
            enrolledRoadmaps = try await languageService.fetchRoadmaps(publishedOnly: true)
        } catch {
            NSLog("⚠️ Failed to load roadmaps: \(error.localizedDescription)")
        }
    }

    // MARK: - In-Progress Lessons

    /// Load in-progress lessons across all roadmaps
    private func loadInProgressLessons() async {
        var allInProgress: [LessonWithRoadmap] = []

        for roadmap in enrolledRoadmaps {
            do {
                let lessons = try await lessonService.fetchLessons(
                    roadmapId: roadmap.id,
                    publishedOnly: true,
                    limit: 50
                )

                // Filter for in-progress lessons
                let inProgress = lessons.filter { $0.isInProgress }

                // Wrap with roadmap info
                let lessonsWithRoadmap = inProgress.map { lesson in
                    LessonWithRoadmap(lesson: lesson, roadmap: roadmap)
                }

                allInProgress.append(contentsOf: lessonsWithRoadmap)
            } catch {
                NSLog("⚠️ Failed to load lessons for roadmap \(roadmap.id): \(error.localizedDescription)")
            }
        }

        // Sort by last accessed date (most recent first)
        inProgressLessons = allInProgress.sorted { first, second in
            guard let firstDate = first.lesson.userProgress?.lastAccessedAt,
                  let secondDate = second.lesson.userProgress?.lastAccessedAt else {
                return false
            }
            return firstDate > secondDate
        }
    }

    // MARK: - Recently Completed Lessons

    /// Load recently completed lessons
    private func loadRecentlyCompletedLessons() async {
        var allCompleted: [LessonWithRoadmap] = []

        for roadmap in enrolledRoadmaps {
            do {
                let lessons = try await lessonService.fetchLessons(
                    roadmapId: roadmap.id,
                    publishedOnly: true,
                    limit: 50
                )

                // Filter for completed lessons
                let completed = lessons.filter { $0.isCompleted }

                // Wrap with roadmap info
                let lessonsWithRoadmap = completed.map { lesson in
                    LessonWithRoadmap(lesson: lesson, roadmap: roadmap)
                }

                allCompleted.append(contentsOf: lessonsWithRoadmap)
            } catch {
                NSLog("⚠️ Failed to load lessons for roadmap \(roadmap.id): \(error.localizedDescription)")
            }
        }

        // Sort by completion date (most recent first) and take top 5
        recentlyCompletedLessons = allCompleted.sorted { first, second in
            guard let firstDate = first.lesson.userProgress?.completedAt,
                  let secondDate = second.lesson.userProgress?.completedAt else {
                return false
            }
            return firstDate > secondDate
        }.prefix(5).map { $0 }
    }

    // MARK: - Recommended Lessons

    /// Load recommended next lessons
    private func loadRecommendedLessons() async {
        var allRecommended: [LessonWithRoadmap] = []

        for roadmap in enrolledRoadmaps {
            do {
                let lessons = try await lessonService.fetchLessons(
                    roadmapId: roadmap.id,
                    publishedOnly: true,
                    limit: 50
                )

                // Filter for available (not started, not locked) lessons
                let available = lessons.filter { $0.status == .available }

                // Wrap with roadmap info
                let lessonsWithRoadmap = available.map { lesson in
                    LessonWithRoadmap(lesson: lesson, roadmap: roadmap)
                }

                // Take first 2 from each language
                allRecommended.append(contentsOf: lessonsWithRoadmap.prefix(2))
            } catch {
                NSLog("⚠️ Failed to load lessons for roadmap \(roadmap.id): \(error.localizedDescription)")
            }
        }

        // Sort by lesson order and take top 6
        recommendedLessons = Array(allRecommended.sorted(by: { $0.lesson.lessonNumber < $1.lesson.lessonNumber }).prefix(6))
    }

    // MARK: - Roadmap Progress

    /// Load progress for all enrolled roadmaps
    private func loadAllRoadmapProgress() async {
        for roadmap in enrolledRoadmaps {
            do {
                let progress = try await lessonService.fetchRoadmapProgress(roadmapId: roadmap.id)
                roadmapProgress[roadmap.id] = progress
            } catch {
                NSLog("⚠️ Failed to load progress for roadmap \(roadmap.id): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Helper Methods

    /// Get the most recent in-progress lesson (for hero card)
    var heroLesson: LessonWithRoadmap? {
        inProgressLessons.first
    }

    /// Get in-progress lessons excluding the hero
    var otherInProgressLessons: [LessonWithRoadmap] {
        Array(inProgressLessons.dropFirst())
    }

    /// Check if user has any learning activity
    var hasAnyActivity: Bool {
        !inProgressLessons.isEmpty || !recentlyCompletedLessons.isEmpty
    }

    /// Check if user is enrolled in any languages
    var hasEnrolledLanguages: Bool {
        !enrolledRoadmaps.isEmpty
    }

    /// Get progress for a roadmap
    func getProgress(for roadmapId: String) -> RoadmapProgress? {
        roadmapProgress[roadmapId]
    }

    /// Get roadmap for a lesson
    func getRoadmap(for lesson: Lesson) -> Roadmap? {
        enrolledRoadmaps.first { $0.id == lesson.roadmapId }
    }

    /// Dismiss error
    func dismissError() {
        showError = false
        errorMessage = nil
    }
}

// MARK: - Helper Models

/// Lesson wrapped with its roadmap for display
struct LessonWithRoadmap: Identifiable, Hashable {
    let lesson: Lesson
    let roadmap: Roadmap

    var id: String {
        lesson.id
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(lesson.id)
        hasher.combine(roadmap.id)
    }

    static func == (lhs: LessonWithRoadmap, rhs: LessonWithRoadmap) -> Bool {
        lhs.lesson.id == rhs.lesson.id && lhs.roadmap.id == rhs.roadmap.id
    }

    // MARK: - Convenience Properties

    var languageName: String {
        roadmap.languageName
    }

    var languageFlag: String {
        roadmap.languageFlag
    }

    var languageCode: String {
        roadmap.language?.code ?? ""
    }

    var progressPercentage: Double {
        lesson.userProgress?.progressPercentage ?? 0
    }

    var currentPhase: Int {
        lesson.userProgress?.currentPhase ?? 1
    }

    var totalPhases: Int {
        4  // Standard 4-phase lesson
    }

    var scorePercentage: Int {
        lesson.userProgress?.scorePercentage ?? 0
    }

    var completedAt: Date? {
        lesson.userProgress?.completedAt
    }

    var lastAccessedAt: Date? {
        lesson.userProgress?.lastAccessedAt
    }

    var timeAgo: String {
        guard let date = lastAccessedAt ?? completedAt else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
