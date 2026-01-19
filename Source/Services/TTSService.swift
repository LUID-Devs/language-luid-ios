//
//  TTSService.swift
//  LanguageLuid
//
//  Text-to-Speech service using backend Gemini GenAI TTS
//

import Foundation
import os.log

/// TTS Service for generating speech audio
@MainActor
final class TTSService {
    static let shared = TTSService()

    // MARK: - Properties

    private let apiClient = APIClient.shared
    private let logger = OSLog(subsystem: "com.luid.languageluid", category: "TTSService")

    // Audio cache
    private var audioCache: [String: Data] = [:]

    // MARK: - Initialization

    private init() {}

    // MARK: - API Methods

    /// Synthesize speech using Gemini GenAI TTS
    /// - Parameters:
    ///   - text: Text to synthesize
    ///   - languageCode: Language code (e.g., "es-ES", "fr-FR")
    ///   - voiceName: Optional voice name (defaults to language-appropriate voice)
    ///   - speed: Speech speed (0.5x to 2.0x, default 1.0)
    /// - Returns: Audio data (MP3 format)
    func synthesize(
        text: String,
        languageCode: String,
        voiceName: String? = nil,
        speed: Float = 1.0
    ) async throws -> Data {
        os_log("Synthesizing speech for text: %{public}@ (language: %{public}@)",
               log: logger, type: .info, text, languageCode)

        // Check cache first
        let cacheKey = "\(languageCode)_\(text)_\(speed)"
        if let cachedAudio = audioCache[cacheKey] {
            os_log("Using cached audio for text: %{public}@", log: logger, type: .info, text)
            return cachedAudio
        }

        // Prepare request
        let parameters: [String: Any] = [
            "text": text,
            "language_code": languageCode,
            "voice_name": voiceName ?? "",
            "speed": speed
        ]

        struct SynthesizeResponse: Codable {
            let success: Bool
            let audioContent: String
            let voiceUsed: String?

            enum CodingKeys: String, CodingKey {
                case success
                case audioContent = "audio_content"
                case voiceUsed = "voice_used"
            }
        }

        // Make API request
        let response: SynthesizeResponse = try await apiClient.post(
            "/speech/synthesize-genai",
            parameters: parameters,
            requiresAuth: false // TTS is public
        )

        guard response.success else {
            os_log("TTS synthesis failed", log: logger, type: .error)
            throw APIError.serverError("TTS synthesis failed")
        }

        // Decode base64 audio
        guard let audioData = Data(base64Encoded: response.audioContent) else {
            os_log("Failed to decode base64 audio", log: logger, type: .error)
            throw APIError.serverError("Failed to decode audio data")
        }

        os_log("Successfully synthesized %{public}d bytes of audio",
               log: logger, type: .info, audioData.count)

        // Cache the audio
        audioCache[cacheKey] = audioData

        return audioData
    }

    /// Get pronunciation guide with normal and slow versions
    /// - Parameters:
    ///   - text: Text to get pronunciation for
    ///   - languageCode: Language code
    /// - Returns: Tuple of (normal audio, slow audio)
    func getPronunciationGuide(
        text: String,
        languageCode: String
    ) async throws -> (normal: Data, slow: Data) {
        os_log("Getting pronunciation guide for: %{public}@", log: logger, type: .info, text)

        let parameters: [String: Any] = [
            "text": text,
            "language_code": languageCode
        ]

        struct PronunciationResponse: Codable {
            let success: Bool
            let normalAudio: String
            let slowAudio: String

            enum CodingKeys: String, CodingKey {
                case success
                case normalAudio = "normal_audio"
                case slowAudio = "slow_audio"
            }
        }

        let response: PronunciationResponse = try await apiClient.post(
            "/speech/pronunciation-guide-genai",
            parameters: parameters,
            requiresAuth: false
        )

        guard response.success else {
            os_log("Pronunciation guide request failed", log: logger, type: .error)
            throw APIError.serverError("Pronunciation guide request failed")
        }

        // Decode audio data
        guard let normalData = Data(base64Encoded: response.normalAudio),
              let slowData = Data(base64Encoded: response.slowAudio) else {
            os_log("Failed to decode pronunciation audio", log: logger, type: .error)
            throw APIError.serverError("Failed to decode audio data")
        }

        os_log("Successfully retrieved pronunciation guide", log: logger, type: .info)

        return (normal: normalData, slow: slowData)
    }

    /// Get available voices for a language
    /// - Parameter languageCode: Language code (e.g., "es", "fr")
    /// - Returns: Array of available voices
    func getAvailableVoices(for languageCode: String) async throws -> [TTSVoice] {
        os_log("Fetching voices for language: %{public}@", log: logger, type: .info, languageCode)

        let voices: [TTSVoice] = try await apiClient.get(
            "/speech/genai-voices/\(languageCode)",
            requiresAuth: false
        )

        os_log("Found %{public}d voices for language: %{public}@",
               log: logger, type: .info, voices.count, languageCode)

        return voices
    }

    /// Get all available voices
    /// - Returns: Array of all voices
    func getAllVoices() async throws -> [TTSVoice] {
        os_log("Fetching all available voices", log: logger, type: .info)

        let voices: [TTSVoice] = try await apiClient.get(
            "/speech/genai-voices",
            requiresAuth: false
        )

        os_log("Found %{public}d total voices", log: logger, type: .info, voices.count)

        return voices
    }

    /// Clear audio cache
    func clearCache() {
        os_log("Clearing TTS audio cache", log: logger, type: .info)
        audioCache.removeAll()
    }

    /// Get cache size in bytes
    var cacheSize: Int {
        return audioCache.values.reduce(0) { $0 + $1.count }
    }
}

// MARK: - TTS Voice Model

struct TTSVoice: Codable, Identifiable {
    let name: String
    let languageCode: String
    let gender: String?
    let description: String?

    var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name
        case languageCode = "language_code"
        case gender
        case description
    }
}
