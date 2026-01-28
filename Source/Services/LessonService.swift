//
//  LessonService.swift
//  LanguageLuid
//
//  Service for lesson operations matching backend roadmap API
//  Handles lessons, phases, exercises, and progress tracking
//

import Foundation
import os.log

// MARK: - API Response Wrappers

struct LessonsResponse: Codable {
    let success: Bool
    let data: [Lesson]
}

struct LessonResponse: Codable {
    let success: Bool
    let data: Lesson
}

struct LessonPhasesResponse: Codable {
    let success: Bool
    let data: [LessonPhaseDefinition]
}

struct ExercisesResponse: Codable {
    let success: Bool
    let data: [Exercise]
}

struct ExerciseResultResponse: Codable {
    let success: Bool
    let data: ExerciseResult
}

struct UserLessonProgressResponse: Codable {
    let success: Bool
    let data: UserLessonProgress
}

struct StartLessonData: Codable {
    let progress: UserLessonProgress
    let lesson: PartialLesson
}

struct PartialLesson: Codable {
    let id: String
    let lessonNumber: Int
    let lessonCode: String
    let title: String
}

struct StartLessonResponse: Codable {
    let success: Bool
    let message: String?
    let data: StartLessonData
}

struct PhaseProgressSummaryResponse: Codable {
    let success: Bool
    let data: PhaseProgressSummary
}

struct ProgressStatsResponse: Codable {
    let success: Bool
    let data: ProgressStats
}

struct RoadmapProgressResponse: Codable {
    let success: Bool
    let data: RoadmapProgress
}

struct SaveStepProgressResponse: Codable {
    let success: Bool
    let message: String?
    // We don't need to decode the data since we just care about success
}

struct CompletePhaseData: Codable {
    let progress: UserLessonProgress
    let phaseCompleted: Int
    let lessonCompleted: Bool
}

struct CompletePhaseResponse: Codable {
    let success: Bool
    let data: CompletePhaseData
    let message: String?
}

// MARK: - Lesson Service

@MainActor
class LessonService {
    static let shared = LessonService()

    private let apiClient: APIClient
    private let logger = OSLog(subsystem: "com.luid.languageluid", category: "LessonService")

    private init() {
        self.apiClient = APIClient.shared
    }

    // MARK: - Lesson Fetching

    /// Fetch all lessons for a roadmap
    /// GET /api/roadmaps/:roadmapId/lessons
    /// - Parameters:
    ///   - roadmapId: Roadmap UUID
    ///   - cefrLevel: Filter by CEFR level (optional)
    ///   - category: Filter by category (optional)
    ///   - lessonType: Filter by lesson type (optional)
    ///   - publishedOnly: Only return published lessons (default: true)
    ///   - limit: Maximum number of results
    ///   - offset: Pagination offset
    func fetchLessons(
        roadmapId: String,
        cefrLevel: CEFRLevel? = nil,
        category: LessonCategory? = nil,
        lessonType: LessonType? = nil,
        publishedOnly: Bool = true,
        limit: Int? = nil,
        offset: Int? = nil
    ) async throws -> [Lesson] {
        os_log("📚 Fetching lessons...", log: logger, type: .info)

        var parameters: [String: Any] = [:]
        if let level = cefrLevel {
            parameters["cefrLevel"] = level.rawValue
        }
        if let cat = category {
            parameters["category"] = cat.rawValue
        }
        if let type = lessonType {
            parameters["lessonType"] = type.rawValue
        }
        if publishedOnly {
            parameters["publishedOnly"] = "true"
        }
        if let limit = limit {
            parameters["limit"] = limit
        }
        if let offset = offset {
            parameters["offset"] = offset
        }

        do {
            let response: LessonsResponse = try await apiClient.get(
                "\(APIEndpoint.roadmaps)/\(roadmapId)/lessons",
                parameters: parameters,
                requiresAuth: true
            )

            os_log("✅ Fetched %{public}d lessons", log: logger, type: .info, response.data.count)

            return response.data
        } catch {
            os_log("❌ Failed to fetch lessons: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    /// Fetch specific lesson details
    /// GET /api/roadmaps/:roadmapId/lessons/:lessonId
    /// - Parameters:
    ///   - roadmapId: Roadmap UUID
    ///   - lessonId: Lesson UUID
    ///   - includePhases: Include phase definitions (default: false)
    ///   - includeExercises: Include exercises (default: false)
    ///   - regionalVariantId: Regional variant UUID (optional)
    func fetchLesson(
        roadmapId: String,
        lessonId: String,
        includePhases: Bool = false,
        includeExercises: Bool = false,
        regionalVariantId: String? = nil
    ) async throws -> Lesson {
        os_log("📖 Fetching lesson...", log: logger, type: .info)

        var parameters: [String: Any] = [:]
        if includePhases {
            parameters["includePhases"] = "true"
        }
        if includeExercises {
            parameters["includeExercises"] = "true"
        }
        if let variantId = regionalVariantId {
            parameters["regionalVariantId"] = variantId
        }

        do {
            let response: LessonResponse = try await apiClient.get(
                "\(APIEndpoint.roadmaps)/\(roadmapId)/lessons/\(lessonId)",
                parameters: parameters,
                requiresAuth: true
            )

            os_log("✅ Fetched lesson: %{public}@", log: logger, type: .info, response.data.title)

            return response.data
        } catch {
            os_log("❌ Failed to fetch lesson: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    /// Fetch lesson by lesson number
    /// GET /api/roadmaps/:roadmapId/lessons/number/:lessonNumber
    /// - Parameters:
    ///   - roadmapId: Roadmap UUID
    ///   - lessonNumber: Lesson number (e.g., 1 for L1)
    func fetchLesson(
        roadmapId: String,
        lessonNumber: Int
    ) async throws -> Lesson {
        os_log("📖 Fetching lesson number: %{public}d", log: logger, type: .info, lessonNumber)

        do {
            let response: LessonResponse = try await apiClient.get(
                "\(APIEndpoint.roadmaps)/\(roadmapId)/lessons/number/\(lessonNumber)",
                requiresAuth: true
            )

            os_log("✅ Fetched lesson: %{public}@", log: logger, type: .info, response.data.title)

            return response.data
        } catch {
            os_log("❌ Failed to fetch lesson by number: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    // MARK: - Lesson Phases

    /// Fetch lesson phase definitions
    /// GET /api/roadmaps/:roadmapId/lessons/:lessonId/phases
    /// - Parameters:
    ///   - roadmapId: Roadmap UUID
    ///   - lessonId: Lesson UUID
    func fetchLessonPhases(
        roadmapId: String,
        lessonId: String
    ) async throws -> [LessonPhaseDefinition] {
        let url = "\(APIEndpoint.roadmaps)/\(roadmapId)/lessons/\(lessonId)/phases"
        os_log("📝 Fetching lesson phases...", log: logger, type: .info)

        do {
            let response: LessonPhasesResponse = try await apiClient.get(
                url,
                requiresAuth: true
            )

            os_log("✅ Fetched %{public}d phases", log: logger, type: .info, response.data.count)

            return response.data
        } catch {
            os_log("❌ Failed to fetch lesson phases: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    // MARK: - Lesson Exercises

    /// Fetch lesson exercises
    /// GET /api/roadmaps/:roadmapId/lessons/:lessonId/exercises
    /// - Parameters:
    ///   - roadmapId: Roadmap UUID
    ///   - lessonId: Lesson UUID
    ///   - phaseNumber: Filter by phase number (1-4) (optional)
    func fetchLessonExercises(
        roadmapId: String,
        lessonId: String,
        phaseNumber: Int? = nil
    ) async throws -> [Exercise] {
        os_log("💪 Fetching lesson exercises...", log: logger, type: .info)

        var parameters: [String: Any] = [:]
        if let phase = phaseNumber {
            parameters["phaseNumber"] = phase
        }

        do {
            let response: ExercisesResponse = try await apiClient.get(
                "\(APIEndpoint.roadmaps)/\(roadmapId)/lessons/\(lessonId)/exercises",
                parameters: parameters,
                requiresAuth: true
            )

            os_log("✅ Fetched %{public}d exercises", log: logger, type: .info, response.data.count)

            return response.data
        } catch {
            os_log("❌ Failed to fetch exercises: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    // MARK: - Lesson Progress

    /// Start a lesson (creates progress record)
    /// POST /api/roadmaps/:roadmapId/lessons/:lessonId/start
    /// - Parameters:
    ///   - roadmapId: Roadmap UUID
    ///   - lessonId: Lesson UUID
    func startLesson(
        roadmapId: String,
        lessonId: String
    ) async throws -> UserLessonProgress {
        os_log("▶️ Starting lesson...", log: logger, type: .info)

        do {
            let response: StartLessonResponse = try await apiClient.post(
                "\(APIEndpoint.roadmaps)/\(roadmapId)/lessons/\(lessonId)/start",
                requiresAuth: true
            )

            os_log("✅ Lesson started", log: logger, type: .info)

            return response.data.progress
        } catch {
            os_log("❌ Failed to start lesson: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    /// Submit an exercise response
    /// POST /api/roadmaps/:roadmapId/lessons/:lessonId/exercises/:exerciseId/submit
    /// - Parameters:
    ///   - roadmapId: Roadmap UUID
    ///   - lessonId: Lesson UUID
    ///   - exerciseId: Exercise UUID
    ///   - response: User's exercise response
    func submitExercise(
        roadmapId: String,
        lessonId: String,
        exerciseId: String,
        response: ExerciseResponse
    ) async throws -> ExerciseResult {
        os_log("📝 Submitting exercise...", log: logger, type: .info)

        // Prepare parameters
        var parameters: [String: Any] = [:]

        // Convert ResponseValue to appropriate format
        switch response.response {
        case .string(let value):
            parameters["response"] = value
        case .array(let value):
            parameters["response"] = value
        case .object(let value):
            parameters["response"] = value
        }

        if let timeSpent = response.timeSpent {
            parameters["timeSpent"] = timeSpent
        }

        do {
            let response: ExerciseResultResponse = try await apiClient.post(
                "\(APIEndpoint.roadmaps)/\(roadmapId)/lessons/\(lessonId)/exercises/\(exerciseId)/submit",
                parameters: parameters,
                requiresAuth: true
            )

            let percentage = response.data.percentageScore ?? Int((response.data.score / (response.data.maxScore ?? 1.0)) * 100)
            os_log("✅ Exercise submitted - Score: %{public}d%%", log: logger, type: .info, percentage)

            return response.data
        } catch {
            os_log("❌ Failed to submit exercise: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    /// Complete a lesson phase
    /// POST /api/roadmaps/:roadmapId/lessons/:lessonId/phases/:phaseNumber/complete
    /// - Parameters:
    ///   - roadmapId: Roadmap UUID
    ///   - lessonId: Lesson UUID
    ///   - phaseNumber: Phase number (1-4)
    ///   - score: Phase score (0.0 - 1.0)
    ///   - timeSpent: Time spent in seconds (optional)
    func completePhase(
        roadmapId: String,
        lessonId: String,
        phaseNumber: Int,
        score: Double,
        timeSpent: Int? = nil
    ) async throws {
        os_log("✅ Completing phase %{public}d", log: logger, type: .info, phaseNumber)

        var parameters: [String: Any] = ["score": score]
        if let time = timeSpent {
            parameters["timeSpent"] = time
        }

        do {
            let response: CompletePhaseResponse = try await apiClient.post(
                "\(APIEndpoint.roadmaps)/\(roadmapId)/lessons/\(lessonId)/phases/\(phaseNumber)/complete",
                parameters: parameters,
                requiresAuth: true
            )

            os_log("✅ Phase %{public}d completed (lesson completed: %{public}@) with score: %{public}d%%",
                   log: logger, type: .info,
                   response.data.phaseCompleted,
                   response.data.lessonCompleted ? "YES" : "NO",
                   Int(score * 100))
        } catch {
            os_log("❌ Failed to complete phase: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    /// Save step progress within a phase
    /// PUT /api/roadmaps/:roadmapId/lessons/:lessonId/phases/:phaseNumber/steps
    /// - Parameters:
    ///   - roadmapId: Roadmap UUID
    ///   - lessonId: Lesson UUID
    ///   - phaseNumber: Phase number (1-4)
    ///   - currentStep: Current step index
    ///   - completedSteps: Array of completed step indices
    ///   - stepScores: Dictionary of step scores (optional)
    func saveStepProgress(
        roadmapId: String,
        lessonId: String,
        phaseNumber: Int,
        currentStep: Int,
        completedSteps: [Int],
        stepScores: [String: Double]? = nil
    ) async throws {
        os_log("💾 Saving step progress...", log: logger, type: .info)

        var parameters: [String: Any] = [
            "currentStep": currentStep,
            "completedSteps": completedSteps
        ]
        if let scores = stepScores {
            parameters["stepScores"] = scores
        }

        do {
            // Backend returns a custom response format with success and message
            // We don't need the full data, just confirmation that it was saved
            let response: SaveStepProgressResponse = try await apiClient.put(
                "\(APIEndpoint.roadmaps)/\(roadmapId)/lessons/\(lessonId)/phases/\(phaseNumber)/steps",
                parameters: parameters,
                requiresAuth: true
            )

            if response.success {
                os_log("✅ Step progress saved", log: logger, type: .info)
            } else {
                throw APIError.unknown
            }
        } catch {
            os_log("❌ Failed to save step progress: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    /// Fetch user's progress for a specific lesson
    /// GET /api/roadmaps/:roadmapId/lessons/:lessonId/progress
    /// - Parameters:
    ///   - roadmapId: Roadmap UUID
    ///   - lessonId: Lesson UUID
    func fetchUserProgress(
        roadmapId: String,
        lessonId: String
    ) async throws -> UserLessonProgress {
        os_log("📊 Fetching user progress...", log: logger, type: .info)

        do {
            let response: UserLessonProgressResponse = try await apiClient.get(
                "\(APIEndpoint.roadmaps)/\(roadmapId)/lessons/\(lessonId)/progress",
                requiresAuth: true
            )

            os_log("✅ Fetched user progress", log: logger, type: .info)

            return response.data
        } catch {
            os_log("❌ Failed to fetch user progress: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    /// Fetch phase progress summary
    /// GET /api/lessons/:lessonId/phase-progress
    /// - Parameter lessonId: Lesson UUID
    func fetchPhaseProgress(
        lessonId: String
    ) async throws -> PhaseProgressSummary {
        os_log("📊 Fetching phase progress...", log: logger, type: .info)

        do {
            let response: PhaseProgressSummaryResponse = try await apiClient.get(
                "/lessons/\(lessonId)/phase-progress",
                requiresAuth: true
            )

            os_log("✅ Fetched phase progress", log: logger, type: .info)

            return response.data
        } catch {
            os_log("❌ Failed to fetch phase progress: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    /// Fetch step progress for a specific phase
    /// Gets step progress from the user lesson progress endpoint
    /// - Parameters:
    ///   - roadmapId: Roadmap UUID
    ///   - lessonId: Lesson UUID
    ///   - phaseNumber: Phase number (1-4)
    func fetchStepProgress(
        roadmapId: String,
        lessonId: String,
        phaseNumber: Int
    ) async throws -> LessonPhaseProgress? {
        os_log("📊 Fetching step progress...", log: logger, type: .info)

        do {
            // Use the correct endpoint that includes stepProgress
            let response: UserLessonProgressResponse = try await apiClient.get(
                "\(APIEndpoint.roadmaps)/\(roadmapId)/lessons/\(lessonId)/progress",
                requiresAuth: true
            )

            if let stepProgressDict = response.data.stepProgress {
                let phaseKey = "phase\(phaseNumber)"

                if let stepProgress = stepProgressDict[phaseKey] {
                    os_log("✅ Fetched step progress", log: logger, type: .info)
                    return stepProgress
                } else {
                    return nil
                }
            }

            return nil
        } catch {
            os_log("⚠️ Failed to fetch step progress: %{public}@", log: logger, type: .error, error.localizedDescription)
            // Return nil instead of throwing - step progress may not exist yet
            return nil
        }
    }

    // MARK: - Progress Statistics

    /// Fetch user's overall progress statistics
    /// GET /api/phase-progress/stats
    /// - Parameter languageId: Filter by language (optional)
    func fetchProgressStats(
        languageId: String? = nil
    ) async throws -> ProgressStats {
        os_log("📊 Fetching progress stats...", log: logger, type: .info)

        var parameters: [String: Any] = [:]
        if let langId = languageId {
            parameters["languageId"] = langId
        }

        do {
            let response: ProgressStatsResponse = try await apiClient.get(
                "/phase-progress/stats",
                parameters: parameters,
                requiresAuth: true
            )

            os_log("✅ Fetched progress stats", log: logger, type: .info)

            return response.data
        } catch {
            os_log("❌ Failed to fetch progress stats: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    /// Fetch user's roadmap progress
    /// GET /api/roadmaps/:roadmapId/progress
    /// - Parameter roadmapId: Roadmap UUID
    func fetchRoadmapProgress(
        roadmapId: String
    ) async throws -> RoadmapProgress {
        os_log("📊 Fetching roadmap progress...", log: logger, type: .info)

        do {
            let response: RoadmapProgressResponse = try await apiClient.get(
                "\(APIEndpoint.roadmaps)/\(roadmapId)/progress",
                requiresAuth: true
            )

            os_log("✅ Fetched roadmap progress", log: logger, type: .info)

            return response.data
        } catch {
            os_log("❌ Failed to fetch roadmap progress: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    // MARK: - Helper Methods

    /// Filter lessons by status
    func filterLessons(_ lessons: [Lesson], by status: LessonStatus) -> [Lesson] {
        lessons.filter { $0.status == status }
    }

    /// Sort lessons by lesson number
    func sortLessonsByNumber(_ lessons: [Lesson]) -> [Lesson] {
        lessons.sorted { $0.lessonNumber < $1.lessonNumber }
    }

    /// Get next available lesson
    func getNextLesson(from lessons: [Lesson]) -> Lesson? {
        lessons.first { $0.status == .available || $0.status == .inProgress }
    }

    /// Calculate overall lesson progress percentage
    func calculateProgress(for progress: UserLessonProgress) -> Double {
        guard let total = progress.totalExercises, total > 0,
              let completed = progress.exercisesCompleted else {
            return 0
        }
        return (Double(completed) / Double(total)) * 100
    }
}
