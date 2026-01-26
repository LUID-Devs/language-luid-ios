//
//  LessonViewModel.swift
//  LanguageLuid
//
//  ViewModel for lesson playback and progress tracking
//  Manages lesson state, phases, exercises, and user progress
//

import Foundation
import SwiftUI
import Combine

@MainActor
class LessonViewModel: ObservableObject {
    // MARK: - Published Properties

    // Lessons
    @Published var lessons: [Lesson] = []
    @Published var selectedLesson: Lesson?
    @Published var filteredLessons: [Lesson] = []

    // Phases
    @Published var lessonPhases: [LessonPhaseDefinition] = []
    @Published var currentPhase: LessonPhaseDefinition?
    @Published var phaseProgressSummary: PhaseProgressSummary?

    // Exercises
    @Published var exercises: [Exercise] = []
    @Published var currentExercise: Exercise?
    @Published var currentExerciseIndex: Int = 0

    // Progress
    @Published var userProgress: UserLessonProgress?
    @Published var progressStats: ProgressStats?
    @Published var roadmapProgress: RoadmapProgress?
    @Published var exerciseResult: ExerciseResult?
    @Published var phaseStepProgress: LessonPhaseProgress?

    // UI State
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showSuccess = false
    @Published var successMessage: String?

    // Filters
    @Published var selectedCEFRLevel: CEFRLevel?
    @Published var selectedCategory: LessonCategory?
    @Published var selectedLessonType: LessonType?
    @Published var showCompletedOnly = false
    @Published var showInProgressOnly = false

    // MARK: - Private Properties

    private let lessonService: LessonService
    private var cancellables = Set<AnyCancellable>()
    private var exerciseStartTime: Date?
    private var phaseStartTime: Date?

    // MARK: - Initialization

    init(lessonService: LessonService = .shared) {
        self.lessonService = lessonService
        setupObservers()
    }

    // MARK: - Setup

    private func setupObservers() {
        // Auto-filter lessons when filter criteria changes
        Publishers.CombineLatest4(
            $selectedCEFRLevel,
            $selectedCategory,
            $selectedLessonType,
            Publishers.CombineLatest($showCompletedOnly, $showInProgressOnly)
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.applyFilters()
        }
        .store(in: &cancellables)
    }

    // MARK: - Lesson Loading

    /// Load lessons for a roadmap
    func loadLessons(
        roadmapId: String,
        cefrLevel: CEFRLevel? = nil,
        category: LessonCategory? = nil
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            lessons = try await lessonService.fetchLessons(
                roadmapId: roadmapId,
                cefrLevel: cefrLevel,
                category: category
            )
            if lessons.isEmpty {
                NSLog("⚠️ No lessons returned. Retrying without publishedOnly filter...")
                lessons = try await lessonService.fetchLessons(
                    roadmapId: roadmapId,
                    cefrLevel: cefrLevel,
                    category: category,
                    publishedOnly: false
                )
            }
            filteredLessons = lessons
            NSLog("✅ Loaded \(lessons.count) lessons")
        } catch {
            errorMessage = "Failed to load lessons: \(error.localizedDescription)"
            showError = true
            NSLog("❌ Error loading lessons: \(error)")
        }

        isLoading = false
    }

    /// Load a specific lesson
    func loadLesson(
        roadmapId: String,
        lessonId: String,
        includePhases: Bool = true,
        includeExercises: Bool = false
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            selectedLesson = try await lessonService.fetchLesson(
                roadmapId: roadmapId,
                lessonId: lessonId,
                includePhases: includePhases,
                includeExercises: includeExercises
            )

            if includePhases, let phases = selectedLesson?.phases {
                lessonPhases = phases
                currentPhase = phases.first
            }

            if includeExercises, let exercises = selectedLesson?.exercises {
                self.exercises = exercises
                currentExercise = exercises.first
                currentExerciseIndex = 0
            }

            NSLog("✅ Loaded lesson: \(selectedLesson?.title ?? "Unknown")")
        } catch {
            errorMessage = "Failed to load lesson: \(error.localizedDescription)"
            showError = true
            NSLog("❌ Error loading lesson: \(error)")
        }

        isLoading = false
    }

    /// Load lesson by number
    func loadLesson(
        roadmapId: String,
        lessonNumber: Int
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            selectedLesson = try await lessonService.fetchLesson(
                roadmapId: roadmapId,
                lessonNumber: lessonNumber
            )
            NSLog("✅ Loaded lesson L\(lessonNumber): \(selectedLesson?.title ?? "Unknown")")
        } catch {
            errorMessage = "Failed to load lesson: \(error.localizedDescription)"
            showError = true
            NSLog("❌ Error loading lesson: \(error)")
        }

        isLoading = false
    }

    // MARK: - Phase Management

    /// Load lesson phases
    func loadLessonPhases(roadmapId: String, lessonId: String) async {
        do {
            lessonPhases = try await lessonService.fetchLessonPhases(
                roadmapId: roadmapId,
                lessonId: lessonId
            )
            currentPhase = lessonPhases.first
            NSLog("✅ Loaded \(lessonPhases.count) phases")
        } catch {
            errorMessage = "Failed to load phases: \(error.localizedDescription)"
            showError = true
            NSLog("❌ Error loading phases: \(error)")
        }
    }

    /// Load phase progress
    func loadPhaseProgress(lessonId: String) async {
        do {
            phaseProgressSummary = try await lessonService.fetchPhaseProgress(
                lessonId: lessonId
            )
            NSLog("✅ Loaded phase progress - Current: \(phaseProgressSummary?.currentPhase ?? 0)")
            NSLog("✅ lessonPhases count: \(lessonPhases.count)")
            NSLog("✅ lessonPhases: \(lessonPhases.map { $0.phaseNumber })")

            // Log stepProgress dictionary keys and contents
            if let stepProgress = phaseProgressSummary?.stepProgress {
                NSLog("✅ stepProgress dictionary has \(stepProgress.count) entries")
                for (key, progress) in stepProgress {
                    NSLog("✅ stepProgress['\(key)'] - completed: \(progress.completedSteps?.count ?? 0) steps")
                }
            } else {
                NSLog("⚠️ stepProgress dictionary is nil")
            }

            // Update currentPhase based on progress
            if let currentPhaseNum = phaseProgressSummary?.currentPhase {
                NSLog("✅ Looking for phase number: \(currentPhaseNum)")
                currentPhase = lessonPhases.first { $0.phaseNumber == currentPhaseNum }
                if let currentPhase = currentPhase {
                    NSLog("✅ Set current phase to: \(currentPhase.phaseNumber)")
                } else {
                    NSLog("❌ Could not find phase with number \(currentPhaseNum)")
                }
            } else {
                NSLog("⚠️ phaseProgressSummary.currentPhase is nil")
            }
        } catch {
            NSLog("⚠️ Error loading phase progress: \(error)")
            // Don't show error to user - this is optional data
        }
    }

    /// Move to next phase
    func nextPhase() {
        guard let current = currentPhase else { return }
        if let nextIndex = lessonPhases.firstIndex(where: { $0.phaseNumber == current.phaseNumber + 1 }) {
            currentPhase = lessonPhases[nextIndex]
            phaseStartTime = Date()
        }
    }

    /// Move to previous phase
    func previousPhase() {
        guard let current = currentPhase else { return }
        if let prevIndex = lessonPhases.firstIndex(where: { $0.phaseNumber == current.phaseNumber - 1 }) {
            currentPhase = lessonPhases[prevIndex]
            phaseStartTime = Date()
        }
    }

    /// Select specific phase
    func selectPhase(_ phase: LessonPhaseDefinition) {
        currentPhase = phase
        phaseStartTime = Date()
    }

    // MARK: - Exercise Management

    /// Load exercises for a lesson
    func loadExercises(
        roadmapId: String,
        lessonId: String,
        phaseNumber: Int? = nil
    ) async {
        isLoading = true

        do {
            // Check if task is already cancelled before making network call
            guard !Task.isCancelled else {
                NSLog("⚠️ Task cancelled before loading exercises")
                isLoading = false
                return
            }

            exercises = try await lessonService.fetchLessonExercises(
                roadmapId: roadmapId,
                lessonId: lessonId,
                phaseNumber: phaseNumber
            )

            // Check if task was cancelled during the network call
            guard !Task.isCancelled else {
                NSLog("⚠️ Task cancelled after fetching exercises")
                // Don't update state if cancelled - keep previous state
                isLoading = false
                return
            }

            currentExercise = exercises.first
            currentExerciseIndex = 0
            exerciseStartTime = Date()
            NSLog("✅ Loaded \(exercises.count) exercises for phase \(phaseNumber ?? -1)")
            if let first = exercises.first {
                NSLog("   First exercise: \(first.prompt)")
            }
        } catch is CancellationError {
            // Task was explicitly cancelled - this is normal, don't show error
            NSLog("ℹ️ Exercise loading cancelled (view dismissed)")
            isLoading = false
            return
        } catch {
            // Check if this is a network cancellation error (NSURLError -999)
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                NSLog("ℹ️ Network request cancelled (code -999)")
                // Don't show error to user - this is expected when view dismisses
                isLoading = false
                return
            }

            // For other errors, show to user
            errorMessage = "Failed to load exercises: \(error.localizedDescription)"
            showError = true
            NSLog("❌ Error loading exercises: \(error)")
        }

        isLoading = false
    }

    /// Move to next exercise
    func nextExercise() {
        guard currentExerciseIndex < exercises.count - 1 else { return }
        currentExerciseIndex += 1
        currentExercise = exercises[currentExerciseIndex]
        exerciseStartTime = Date()
        exerciseResult = nil
    }

    /// Move to previous exercise
    func previousExercise() {
        guard currentExerciseIndex > 0 else { return }
        currentExerciseIndex -= 1
        currentExercise = exercises[currentExerciseIndex]
        exerciseStartTime = Date()
        exerciseResult = nil
    }

    /// Check if there is a next exercise
    var hasNextExercise: Bool {
        currentExerciseIndex < exercises.count - 1
    }

    /// Check if there is a previous exercise
    var hasPreviousExercise: Bool {
        currentExerciseIndex > 0
    }

    // MARK: - Progress Tracking

    /// Start a lesson
    func startLesson(roadmapId: String, lessonId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            userProgress = try await lessonService.startLesson(
                roadmapId: roadmapId,
                lessonId: lessonId
            )
            successMessage = "Lesson started!"
            showSuccess = true
            phaseStartTime = Date()

            // Reload phase progress to update currentPhase
            await loadPhaseProgress(lessonId: lessonId)

            NSLog("✅ Lesson started")
        } catch {
            errorMessage = "Failed to start lesson: \(error.localizedDescription)"
            showError = true
            NSLog("❌ Error starting lesson: \(error)")
        }

        isLoading = false
    }

    /// Submit an exercise response
    func submitExercise(
        roadmapId: String,
        lessonId: String,
        exerciseId: String,
        responseValue: ResponseValue
    ) async {
        NSLog("🎯 [ViewModel] submitExercise called for exercise: \(exerciseId)")
        isSubmitting = true
        errorMessage = nil

        // Calculate time spent
        let timeSpent: Int? = exerciseStartTime.map {
            Int(Date().timeIntervalSince($0))
        }

        let response = ExerciseResponse(
            exerciseId: exerciseId,
            response: responseValue,
            timeSpent: timeSpent
        )

        do {
            NSLog("🎯 [ViewModel] Calling lessonService.submitExercise...")
            exerciseResult = try await lessonService.submitExercise(
                roadmapId: roadmapId,
                lessonId: lessonId,
                exerciseId: exerciseId,
                response: response
            )

            NSLog("🎯 [ViewModel] exerciseResult SET: \(exerciseResult != nil ? "YES" : "NO")")
            if let result = exerciseResult {
                NSLog("🎯 [ViewModel] Result details - correct: \(result.isCorrect), score: \(result.score), points: \(result.points ?? -1)")
            }

            if exerciseResult?.passed ?? false {
                let message = exerciseResult?.feedback?.message ?? exerciseResult?.explanation ?? ""
                successMessage = "Correct! \(message)"
                showSuccess = true
            }

            let percentage = exerciseResult?.percentageScore ?? Int((exerciseResult?.score ?? 0) * 100)
            NSLog("✅ Exercise submitted - Score: \(percentage)%")

            // Reload user progress to sync with backend updates
            await loadUserProgress(roadmapId: roadmapId, lessonId: lessonId)
        } catch {
            exerciseResult = nil
            NSLog("🎯 [ViewModel] exerciseResult set to NIL due to error")
            errorMessage = "Failed to submit exercise: \(error.localizedDescription)"
            showError = true
            NSLog("❌ Error submitting exercise: \(error)")
        }

        isSubmitting = false
        NSLog("🎯 [ViewModel] submitExercise completed, exerciseResult is \(exerciseResult != nil ? "SET" : "NIL")")
    }

    /// Complete a phase
    func completePhase(
        roadmapId: String,
        lessonId: String,
        phaseNumber: Int,
        score: Double
    ) async {
        isLoading = true
        errorMessage = nil

        // Calculate time spent
        let timeSpent: Int? = phaseStartTime.map {
            Int(Date().timeIntervalSince($0))
        }

        do {
            try await lessonService.completePhase(
                roadmapId: roadmapId,
                lessonId: lessonId,
                phaseNumber: phaseNumber,
                score: score,
                timeSpent: timeSpent
            )

            successMessage = "Phase \(phaseNumber) completed with \(Int(score * 100))%!"
            showSuccess = true

            // Reload progress
            await loadUserProgress(roadmapId: roadmapId, lessonId: lessonId)

            NSLog("✅ Phase completed")
        } catch {
            errorMessage = "Failed to complete phase: \(error.localizedDescription)"
            showError = true
            NSLog("❌ Error completing phase: \(error)")
        }

        isLoading = false
    }

    /// Save step progress
    func saveStepProgress(
        roadmapId: String,
        lessonId: String,
        phaseNumber: Int,
        currentStep: Int,
        completedSteps: [Int]
    ) async {
        do {
            try await lessonService.saveStepProgress(
                roadmapId: roadmapId,
                lessonId: lessonId,
                phaseNumber: phaseNumber,
                currentStep: currentStep,
                completedSteps: completedSteps
            )
            NSLog("✅ Step progress saved - Phase \(phaseNumber), Step \(currentStep)")
        } catch {
            NSLog("❌ Failed to save step progress: \(error)")
            // Show error to user so they know progress wasn't saved
            errorMessage = "Progress save failed. Please check your connection and try again."
            showError = true
        }
    }

    /// Load step progress for a specific phase
    func loadStepProgress(
        roadmapId: String,
        lessonId: String,
        phaseNumber: Int
    ) async {
        do {
            phaseStepProgress = try await lessonService.fetchStepProgress(
                roadmapId: roadmapId,
                lessonId: lessonId,
                phaseNumber: phaseNumber
            )
            if let progress = phaseStepProgress {
                NSLog("✅ Loaded step progress - Current step: \(progress.currentStep ?? 0), Completed steps: \(progress.completedSteps ?? [])")
            } else {
                NSLog("ℹ️ No step progress found - starting from beginning")
            }
        } catch {
            NSLog("⚠️ Error loading step progress: \(error)")
            // Don't show error - progress may not exist yet
            phaseStepProgress = nil
        }
    }

    /// Load user progress for a lesson
    func loadUserProgress(roadmapId: String, lessonId: String) async {
        do {
            userProgress = try await lessonService.fetchUserProgress(
                roadmapId: roadmapId,
                lessonId: lessonId
            )
            NSLog("✅ Loaded user progress - Status: \(userProgress?.status.rawValue ?? "unknown")")
            NSLog("✅ Current phase: \(userProgress?.currentPhase ?? -1)")

            // Log stepProgress dictionary from userProgress
            if let stepProgress = userProgress?.stepProgress {
                NSLog("✅ userProgress.stepProgress dictionary has \(stepProgress.count) entries")
                for (key, progress) in stepProgress {
                    NSLog("✅ userProgress.stepProgress['\(key)'] - currentStep: \(progress.currentStep ?? -1), completed: \(progress.completedSteps?.count ?? 0) steps")
                    if let completedSteps = progress.completedSteps {
                        NSLog("✅   Completed step indices: \(completedSteps)")
                    }
                }
            } else {
                NSLog("⚠️ userProgress.stepProgress dictionary is nil")
            }
        } catch {
            NSLog("⚠️ Error loading user progress: \(error)")
            // Don't show error - progress may not exist yet
        }
    }

    /// Load progress statistics
    func loadProgressStats(languageId: String? = nil) async {
        do {
            progressStats = try await lessonService.fetchProgressStats(
                languageId: languageId
            )
            NSLog("✅ Loaded progress stats")
        } catch {
            NSLog("⚠️ Error loading progress stats: \(error)")
        }
    }

    /// Load roadmap progress
    func loadRoadmapProgress(roadmapId: String) async {
        do {
            roadmapProgress = try await lessonService.fetchRoadmapProgress(
                roadmapId: roadmapId
            )
            NSLog("✅ Loaded roadmap progress")
        } catch {
            NSLog("⚠️ Error loading roadmap progress: \(error)")
        }
    }

    // MARK: - Filtering

    /// Apply filters to lessons
    private func applyFilters() {
        var filtered = lessons

        // Filter by CEFR level
        if let level = selectedCEFRLevel {
            filtered = filtered.filter { $0.cefrLevel == level }
        }

        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }

        // Filter by lesson type
        if let type = selectedLessonType {
            filtered = filtered.filter { $0.lessonType == type }
        }

        // Filter by completion status
        if showCompletedOnly {
            filtered = filtered.filter { $0.isCompleted }
        } else if showInProgressOnly {
            filtered = filtered.filter { $0.isInProgress }
        }

        filteredLessons = filtered
    }

    /// Clear all filters
    func clearFilters() {
        selectedCEFRLevel = nil
        selectedCategory = nil
        selectedLessonType = nil
        showCompletedOnly = false
        showInProgressOnly = false
        filteredLessons = lessons
    }

    // MARK: - Helper Methods

    /// Get lessons by status
    func getLessons(by status: LessonStatus) -> [Lesson] {
        lessons.filter { $0.status == status }
    }

    /// Get completed lessons
    var completedLessons: [Lesson] {
        getLessons(by: .completed)
    }

    /// Get in-progress lessons
    var inProgressLessons: [Lesson] {
        getLessons(by: .inProgress)
    }

    /// Get available lessons
    var availableLessons: [Lesson] {
        getLessons(by: .available)
    }

    /// Get next available lesson
    var nextLesson: Lesson? {
        lessonService.getNextLesson(from: lessons)
    }

    /// Calculate overall progress percentage
    var overallProgress: Double {
        guard !lessons.isEmpty else { return 0 }
        let completed = completedLessons.count
        return (Double(completed) / Double(lessons.count)) * 100
    }

    /// Check if current exercise is correct
    var isCurrentExerciseCorrect: Bool {
        exerciseResult?.isCorrect ?? false
    }

    /// Get current exercise progress
    var exerciseProgress: Double {
        guard !exercises.isEmpty else { return 0 }
        return (Double(currentExerciseIndex + 1) / Double(exercises.count)) * 100
    }

    /// Get current phase progress
    var phaseProgress: Double {
        guard let summary = phaseProgressSummary else { return 0 }
        return summary.progressPercentage
    }

    // MARK: - Current Lesson Status (with userProgress override)

    /// Get the current lesson status with userProgress override
    /// This prevents the race condition where lesson defaults to locked
    /// before userProgress loads
    var currentLessonStatus: LessonStatus {
        // If we have separate userProgress loaded, use it
        if let progress = userProgress {
            return progress.status
        }
        // Otherwise fall back to lesson's own userProgress
        return selectedLesson?.status ?? .locked
    }

    /// Check if current lesson is locked (respects userProgress override)
    var isCurrentLessonLocked: Bool {
        currentLessonStatus == .locked
    }

    /// Check if current lesson is completed (respects userProgress override)
    var isCurrentLessonCompleted: Bool {
        currentLessonStatus == .completed
    }

    /// Check if current lesson is in progress (respects userProgress override)
    var isCurrentLessonInProgress: Bool {
        currentLessonStatus == .inProgress
    }

    /// Check if current lesson is available (respects userProgress override)
    var isCurrentLessonAvailable: Bool {
        currentLessonStatus == .available
    }

    /// Check if current lesson can be started (not locked and published)
    var canStartCurrentLesson: Bool {
        !isCurrentLessonLocked && (selectedLesson?.isPublished ?? false || AppConfig.isDevelopment)
    }

    /// Reset state
    func reset() {
        selectedLesson = nil
        lessonPhases = []
        currentPhase = nil
        exercises = []
        currentExercise = nil
        currentExerciseIndex = 0
        userProgress = nil
        exerciseResult = nil
        phaseProgressSummary = nil
        exerciseStartTime = nil
        phaseStartTime = nil
        errorMessage = nil
        showError = false
        showSuccess = false
        successMessage = nil
    }

    /// Dismiss errors and success messages
    func dismissMessages() {
        showError = false
        showSuccess = false
        errorMessage = nil
        successMessage = nil
    }
}

// MARK: - Preview Helper
// TODO: Re-enable after fixing mock data
/*
extension LessonViewModel {
    static var preview: LessonViewModel {
        let vm = LessonViewModel()
        vm.lessons = Lesson.mockLessons
        vm.filteredLessons = Lesson.mockLessons
        vm.selectedLesson = Lesson.mock
        vm.lessonPhases = LessonPhaseDefinition.mockPhases
        vm.currentPhase = LessonPhaseDefinition.mockPhase1
        vm.exercises = Exercise.mockExercises
        vm.currentExercise = Exercise.mockMultipleChoice
        vm.userProgress = UserLessonProgress.mock
        vm.progressStats = ProgressStats.mock
        vm.phaseProgressSummary = PhaseProgressSummary.mock
        return vm
    }
}
*/
