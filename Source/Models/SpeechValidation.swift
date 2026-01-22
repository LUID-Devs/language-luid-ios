//
//  SpeechValidation.swift
//  LanguageLuid
//
//  Speech validation models for API responses
//

import Foundation

// MARK: - Speech Validation Response (matches backend structure)

struct SpeechValidationResponse: Codable {
    let success: Bool
    let validation: ValidationResult
    let feedback: ValidationFeedback
    let progression: ProgressionInfo
    let details: ValidationDetails
}

// MARK: - Validation Result

struct ValidationResult: Codable {
    let id: String?
    let stepIndex: Int
    let attemptNumber: Int
    let transcription: String
    let expectedText: String
    let score: Double
    let scorePercentage: Int
    let accuracy: Double
    let passed: Bool
    let scoreLevel: String
    let languageMismatch: Bool
}

// MARK: - Validation Feedback

struct ValidationFeedback: Codable {
    let overall: String
    let level: String
    let suggestions: [String]
    let encouragement: String?
    let details: [String]?
}

// MARK: - Progression Info

struct ProgressionInfo: Codable {
    let canProceed: Bool
    let reason: String
    let message: String
    let suggestions: [String]?
}

// MARK: - Validation Details

struct ValidationDetails: Codable {
    let wordAnalysis: WordAnalysisDetails?
    let processingTime: Int
    let languageInfo: LanguageInfo
}

// MARK: - Word Analysis Details

struct WordAnalysisDetails: Codable {
    let accuracy: Double
    let totalExpected: Int
    let totalSpoken: Int
    let matchCount: Int
    let matches: [String]
    let missing: [String]
    let extra: [String]
    let incorrect: [String]
    let alignment: [WordAlignment]
}

// MARK: - Word Alignment

struct WordAlignment: Codable {
    let type: String
    let expected: String
    let spoken: String?
    let position: Int
}

// MARK: - Language Info

struct LanguageInfo: Codable {
    let expected: String
    let detected: String?
    let match: Bool
}

// MARK: - Validation Rating Helper

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

    init(from scoreLevel: String) {
        switch scoreLevel.lowercased() {
        case "excellent":
            self = .excellent
        case "good":
            self = .good
        case "acceptable":
            self = .acceptable
        case "needs_improvement", "fair":
            self = .needsImprovement
        case "poor":
            self = .poor
        default:
            self = .acceptable
        }
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
