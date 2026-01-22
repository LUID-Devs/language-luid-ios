//
//  SpeechValidationService.swift
//  LanguageLuid
//
//  Service for speech validation API calls
//

import Foundation
import os.log

/// Speech validation service
@MainActor
final class SpeechValidationService {
    static let shared = SpeechValidationService()

    // MARK: - Properties

    private let apiClient = APIClient.shared
    private let logger = OSLog(subsystem: "com.luid.languageluid", category: "SpeechValidation")

    // MARK: - Initialization

    private init() {}

    // MARK: - API Methods

    /// Validate speech recording
    /// - Parameters:
    ///   - audioFileURL: URL to the recorded audio file
    ///   - lessonId: ID of the lesson
    ///   - stepIndex: Index of the step within the lesson
    ///   - expectedText: Expected transcription text
    ///   - languageCode: Language code (e.g., "es", "fr")
    /// - Returns: Speech validation response
    func validateSpeech(
        audioFileURL: URL,
        lessonId: String,
        stepIndex: Int,
        expectedText: String,
        languageCode: String
    ) async throws -> SpeechValidationResponse {
        os_log("Validating speech for lesson %{public}@ step %{public}d",
               log: logger, type: .info, lessonId, stepIndex)

        // Read audio file data
        guard let audioData = try? Data(contentsOf: audioFileURL) else {
            os_log("Failed to read audio file at: %{public}@",
                   log: logger, type: .error, audioFileURL.path)
            throw APIError.serverError("Failed to read audio file")
        }

        os_log("Audio file size: %{public}d bytes", log: logger, type: .info, audioData.count)

        // Create request parameters (must be String values for multipart)
        // NOTE: Backend expects camelCase parameter names!
        let parameters: [String: String] = [
            "expectedText": expectedText,
            "stepType": "phrase_practice", // Match backend default
            "languageCode": languageCode
        ]

        // Upload audio file with multipart/form-data
        let response: SpeechValidationResponse = try await apiClient.uploadAudio(
            "/lessons/\(lessonId)/steps/\(stepIndex)/validate",
            fileData: audioData,
            fileName: "recording.m4a",
            mimeType: "audio/m4a",
            parameters: parameters
        )

        os_log("Speech validation completed. Passed: %{public}@, Score: %.2f",
               log: logger, type: .info,
               response.validation.passed ? "YES" : "NO",
               response.validation.score)

        return response
    }

    /// Get validation history for a step
    func getValidationHistory(
        lessonId: String,
        stepIndex: Int
    ) async throws -> [SpeechValidationResponse] {
        os_log("Fetching validation history for lesson %{public}@ step %{public}d",
               log: logger, type: .info, lessonId, stepIndex)

        let history: [SpeechValidationResponse] = try await apiClient.get(
            "/lessons/\(lessonId)/steps/\(stepIndex)/history"
        )

        os_log("Retrieved %{public}d validation attempts",
               log: logger, type: .info, history.count)

        return history
    }

    /// Check if step is accessible
    func checkStepAccess(
        lessonId: String,
        stepIndex: Int
    ) async throws -> Bool {
        os_log("Checking access for lesson %{public}@ step %{public}d",
               log: logger, type: .info, lessonId, stepIndex)

        struct AccessResponse: Codable {
            let accessible: Bool
            let reason: String?
        }

        let response: AccessResponse = try await apiClient.get(
            "/lessons/\(lessonId)/steps/\(stepIndex)/access"
        )

        os_log("Step access: %{public}@",
               log: logger, type: .info,
               response.accessible ? "GRANTED" : "DENIED")

        return response.accessible
    }
}
