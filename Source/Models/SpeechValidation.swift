//
//  SpeechValidation.swift
//  LanguageLuid
//
//  Speech validation models for API responses
//

import Foundation

// MARK: - Speech Validation Response

struct SpeechValidationResponse: Codable {
    let success: Bool
    let passed: Bool
    let transcription: String?
    let overallScore: Double
    let rating: ValidationRating
    let feedback: ValidationFeedback
    let wordAnalysis: [WordAnalysis]?
    let pronunciationDetails: PronunciationDetails?
    let attemptCount: Int
    let canRetry: Bool
    let languageMismatch: Bool?

    enum CodingKeys: String, CodingKey {
        case success, passed, transcription
        case overallScore = "overall_score"
        case rating, feedback
        case wordAnalysis = "word_analysis"
        case pronunciationDetails = "pronunciation_details"
        case attemptCount = "attempt_count"
        case canRetry = "can_retry"
        case languageMismatch = "language_mismatch"
    }
}

// MARK: - Validation Rating

enum ValidationRating: String, Codable {
    case excellent = "excellent"
    case good = "good"
    case acceptable = "acceptable"
    case needsImprovement = "needs_improvement"
    case poor = "poor"

    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .acceptable: return "Acceptable"
        case .needsImprovement: return "Needs Improvement"
        case .poor: return "Poor"
        }
    }

    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .acceptable: return "yellow"
        case .needsImprovement: return "orange"
        case .poor: return "red"
        }
    }

    var systemImageName: String {
        switch self {
        case .excellent: return "star.fill"
        case .good: return "hand.thumbsup.fill"
        case .acceptable: return "checkmark.circle.fill"
        case .needsImprovement: return "exclamationmark.triangle.fill"
        case .poor: return "xmark.circle.fill"
        }
    }
}

// MARK: - Validation Feedback

struct ValidationFeedback: Codable {
    let message: String
    let suggestions: [String]
    let encouragement: String?

    var allSuggestions: String {
        suggestions.joined(separator: "\n• ")
    }
}

// MARK: - Word Analysis

struct WordAnalysis: Codable, Identifiable {
    let word: String
    let expected: String?
    let actual: String?
    let correct: Bool
    let score: Double?

    var id: String { word }

    enum CodingKeys: String, CodingKey {
        case word, expected, actual, correct, score
    }
}

// MARK: - Pronunciation Details

struct PronunciationDetails: Codable {
    let phonemes: [PhonemeAnalysis]?
    let accuracy: Double?
    let fluency: Double?
    let prosody: Double?
    let completeness: Double?

    enum CodingKeys: String, CodingKey {
        case phonemes, accuracy, fluency, prosody, completeness
    }
}

// MARK: - Phoneme Analysis

struct PhonemeAnalysis: Codable, Identifiable {
    let phoneme: String
    let score: Double
    let feedback: String?

    var id: String { phoneme }

    enum CodingKeys: String, CodingKey {
        case phoneme, score, feedback
    }
}

// MARK: - Score Thresholds

enum ScoreThreshold {
    static let excellent: Double = 0.95
    static let good: Double = 0.85
    static let acceptable: Double = 0.75
    static let pass: Double = 0.70

    static func rating(for score: Double) -> ValidationRating {
        if score >= excellent {
            return .excellent
        } else if score >= good {
            return .good
        } else if score >= acceptable {
            return .acceptable
        } else if score >= pass {
            return .needsImprovement
        } else {
            return .poor
        }
    }

    static func passed(score: Double) -> Bool {
        return score >= pass
    }
}
