//
//  Exercise.swift
//  LanguageLuid
//
//  Exercise models for all exercise types
//  Supports multiple choice, fill-in-blank, matching, speech recognition, etc.
//

import Foundation

// MARK: - Exercise Model

struct Exercise: Codable, Identifiable, Hashable {
    let id: String
    let lessonId: String
    let phaseDefinitionId: String?
    let exerciseType: ExerciseType
    let prompt: String
    let promptAudioUrl: String?
    let expectedResponse: String?
    let acceptableResponses: [String]?
    let options: [ExerciseOption]?
    let hints: [String]?
    let explanation: String?
    let points: Int
    let partialCreditEnabled: Bool
    let difficulty: Int
    let order: Int
    let requiresSpeech: Bool
    let speechConfig: SpeechConfig?
    let metadata: [String: AnyCodable]?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, lessonId, phaseDefinitionId, exerciseType
        case prompt, promptAudioUrl, expectedResponse, acceptableResponses
        case options, hints, explanation, points, partialCreditEnabled
        case difficulty, order, requiresSpeech, speechConfig, metadata
        case isActive, createdAt, updatedAt
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Computed Properties

    var displayType: String {
        exerciseType.displayName
    }

    var icon: String {
        exerciseType.icon
    }

    var hasAudio: Bool {
        promptAudioUrl != nil
    }

    var hasHints: Bool {
        !(hints?.isEmpty ?? true)
    }

    var hasExplanation: Bool {
        explanation != nil && !(explanation?.isEmpty ?? true)
    }

    var isMultipleChoice: Bool {
        exerciseType == .multipleChoice
    }

    var isFillBlank: Bool {
        exerciseType == .fillBlank
    }

    var isMatching: Bool {
        exerciseType == .matching
    }

    var isOrdering: Bool {
        exerciseType == .ordering
    }

    var isTranslation: Bool {
        exerciseType == .translation
    }

    var isSpeechBased: Bool {
        requiresSpeech || exerciseType.isSpeechType
    }

    var canHavePartialCredit: Bool {
        partialCreditEnabled && !isMultipleChoice
    }

    var nextHint: String? {
        hints?.first
    }
}

// MARK: - Exercise Type Enum

enum ExerciseType: String, Codable {
    case multipleChoice = "multiple_choice"
    case fillBlank = "fill_blank"
    case matching = "matching"
    case ordering = "ordering"
    case translation = "translation"
    case speechRecognition = "speech_recognition"
    case speechRepeat = "speech_repeat"
    case speechResponse = "speech_response"
    case listeningComprehension = "listening_comprehension"
    case conversationTurn = "conversation_turn"
    case freeResponse = "free_response"

    var displayName: String {
        switch self {
        case .multipleChoice:
            return "Multiple Choice"
        case .fillBlank:
            return "Fill in the Blank"
        case .matching:
            return "Matching"
        case .ordering:
            return "Order Words"
        case .translation:
            return "Translation"
        case .speechRecognition:
            return "Speech Recognition"
        case .speechRepeat:
            return "Repeat After"
        case .speechResponse:
            return "Speech Response"
        case .listeningComprehension:
            return "Listening"
        case .conversationTurn:
            return "Conversation Turn"
        case .freeResponse:
            return "Free Response"
        }
    }

    var icon: String {
        switch self {
        case .multipleChoice:
            return "list.bullet.circle"
        case .fillBlank:
            return "rectangle.and.pencil.and.ellipsis"
        case .matching:
            return "arrow.left.and.right.square"
        case .ordering:
            return "arrow.up.arrow.down.square"
        case .translation:
            return "arrow.left.arrow.right"
        case .speechRecognition:
            return "waveform.circle"
        case .speechRepeat:
            return "arrow.clockwise.circle"
        case .speechResponse:
            return "mic.circle"
        case .listeningComprehension:
            return "ear"
        case .conversationTurn:
            return "bubble.left.and.bubble.right"
        case .freeResponse:
            return "text.bubble"
        }
    }

    var isSpeechType: Bool {
        switch self {
        case .speechRecognition, .speechRepeat, .speechResponse, .conversationTurn:
            return true
        default:
            return false
        }
    }

    var isListeningType: Bool {
        self == .listeningComprehension
    }

    var needsManualGrading: Bool {
        self == .freeResponse
    }
}

// MARK: - Exercise Option

struct ExerciseOption: Codable, Identifiable, Hashable {
    let id: String
    let text: String
    let isCorrect: Bool
    let explanation: String?
    let audioUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, text, isCorrect, explanation, audioUrl
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: ExerciseOption, rhs: ExerciseOption) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Exercise Response (Submission)

struct ExerciseResponse: Codable {
    let exerciseId: String
    let response: ResponseValue
    let timeSpent: Int?
    let attemptNumber: Int?
    let hintsUsed: Int?

    enum CodingKeys: String, CodingKey {
        case exerciseId, response, timeSpent, attemptNumber, hintsUsed
    }

    init(exerciseId: String, response: ResponseValue, timeSpent: Int? = nil, attemptNumber: Int? = nil, hintsUsed: Int? = nil) {
        self.exerciseId = exerciseId
        self.response = response
        self.timeSpent = timeSpent
        self.attemptNumber = attemptNumber
        self.hintsUsed = hintsUsed
    }
}

// MARK: - Response Value (Can be string, array, or object)

enum ResponseValue: Codable {
    case string(String)
    case array([String])
    case object([String: String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([String].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: String].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode ResponseValue"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }

    var stringValue: String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }

    var arrayValue: [String]? {
        if case .array(let value) = self {
            return value
        }
        return nil
    }

    var objectValue: [String: String]? {
        if case .object(let value) = self {
            return value
        }
        return nil
    }
}

// MARK: - Exercise Result (Feedback)

struct ExerciseResult: Codable, Identifiable {
    let id: String
    let exerciseId: String
    let userId: String?
    let isCorrect: Bool
    let score: Double
    let maxScore: Double
    let percentageScore: Int
    let feedback: ExerciseFeedback
    let correctAnswer: String?
    let userAnswer: String?
    let partialCredit: Bool
    let timeSpent: Int?
    let hintsUsed: Int?
    let attemptNumber: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, exerciseId, userId, isCorrect
        case score, maxScore, percentageScore, feedback
        case correctAnswer, userAnswer, partialCredit
        case timeSpent, hintsUsed, attemptNumber, createdAt
    }

    // MARK: - Computed Properties

    var passed: Bool {
        isCorrect || (partialCredit && percentageScore >= 70)
    }

    var scoreLevel: ScoreLevel {
        switch percentageScore {
        case 90...100:
            return .excellent
        case 80..<90:
            return .good
        case 70..<80:
            return .acceptable
        case 50..<70:
            return .needsImprovement
        default:
            return .poor
        }
    }

    var timeSpentFormatted: String {
        guard let time = timeSpent else { return "N/A" }
        let minutes = time / 60
        let seconds = time % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}

// MARK: - Exercise Feedback

struct ExerciseFeedback: Codable {
    let message: String
    let level: FeedbackLevel
    let suggestions: [String]?
    let highlights: [String]?
    let explanation: String?

    enum CodingKeys: String, CodingKey {
        case message, level, suggestions, highlights, explanation
    }

    var hasSuggestions: Bool {
        !(suggestions?.isEmpty ?? true)
    }

    var hasHighlights: Bool {
        !(highlights?.isEmpty ?? true)
    }

    var hasExplanation: Bool {
        explanation != nil && !(explanation?.isEmpty ?? true)
    }
}

// MARK: - Feedback Level

enum FeedbackLevel: String, Codable {
    case excellent
    case good
    case acceptable
    case needsImprovement = "needs_improvement"
    case poor

    var displayName: String {
        switch self {
        case .excellent:
            return "Excellent!"
        case .good:
            return "Good Job!"
        case .acceptable:
            return "Acceptable"
        case .needsImprovement:
            return "Needs Improvement"
        case .poor:
            return "Try Again"
        }
    }

    var icon: String {
        switch self {
        case .excellent:
            return "star.fill"
        case .good:
            return "hand.thumbsup.fill"
        case .acceptable:
            return "checkmark.circle"
        case .needsImprovement:
            return "exclamationmark.triangle"
        case .poor:
            return "xmark.circle"
        }
    }

    var color: String {
        switch self {
        case .excellent:
            return "yellow"
        case .good:
            return "green"
        case .acceptable:
            return "blue"
        case .needsImprovement:
            return "orange"
        case .poor:
            return "red"
        }
    }
}

// MARK: - Score Level

enum ScoreLevel: String, Codable {
    case excellent
    case good
    case acceptable
    case needsImprovement = "needs_improvement"
    case poor

    var displayName: String {
        switch self {
        case .excellent:
            return "Excellent"
        case .good:
            return "Good"
        case .acceptable:
            return "Acceptable"
        case .needsImprovement:
            return "Needs Improvement"
        case .poor:
            return "Poor"
        }
    }
}

// MARK: - Mock Data for Previews
// TODO: Re-enable after fixing Lesson mock data
/*
extension Exercise {
    static let mockMultipleChoice = Exercise(
        id: "ex-1",
        lessonId: Lesson.mock.id,
        phaseDefinitionId: "phase-1",
        exerciseType: .multipleChoice,
        prompt: "Which word means 'famous'?",
        promptAudioUrl: nil,
        expectedResponse: "famoso",
        acceptableResponses: nil,
        options: [
            ExerciseOption(id: "opt-1", text: "famoso", isCorrect: true, explanation: "Correct! Famoso means famous.", audioUrl: nil),
            ExerciseOption(id: "opt-2", text: "feliz", isCorrect: false, explanation: "No, feliz means happy.", audioUrl: nil),
            ExerciseOption(id: "opt-3", text: "furioso", isCorrect: false, explanation: "No, furioso means furious.", audioUrl: nil),
            ExerciseOption(id: "opt-4", text: "feroz", isCorrect: false, explanation: "No, feroz means fierce.", audioUrl: nil)
        ],
        hints: ["Look for the -oso ending", "Think of English cognates"],
        explanation: "Famoso is a direct cognate from 'famous', following the -ous → -oso pattern.",
        points: 10,
        partialCreditEnabled: false,
        difficulty: 2,
        order: 1,
        requiresSpeech: false,
        speechConfig: nil,
        metadata: nil,
        isActive: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let mockFillBlank = Exercise(
        id: "ex-2",
        lessonId: Lesson.mock.id,
        phaseDefinitionId: "phase-2",
        exerciseType: .fillBlank,
        prompt: "El actor es muy _____. (The actor is very famous.)",
        promptAudioUrl: nil,
        expectedResponse: "famoso",
        acceptableResponses: ["famoso"],
        options: nil,
        hints: ["Think about the cognate pattern", "Ends with -oso"],
        explanation: "Famoso means famous in Spanish.",
        points: 15,
        partialCreditEnabled: true,
        difficulty: 3,
        order: 2,
        requiresSpeech: false,
        speechConfig: nil,
        metadata: nil,
        isActive: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let mockSpeechRecognition = Exercise(
        id: "ex-3",
        lessonId: Lesson.mock.id,
        phaseDefinitionId: "phase-4",
        exerciseType: .speechRepeat,
        prompt: "Repeat: 'Es muy famoso'",
        promptAudioUrl: "https://example.com/audio/es-muy-famoso.mp3",
        expectedResponse: "es muy famoso",
        acceptableResponses: ["es muy famoso", "es muyfamoso"],
        options: nil,
        hints: ["Listen carefully", "Pronounce each word clearly"],
        explanation: "Practice the pronunciation of 'Es muy famoso' (It is very famous).",
        points: 20,
        partialCreditEnabled: true,
        difficulty: 4,
        order: 3,
        requiresSpeech: true,
        speechConfig: SpeechConfig(rate: 0.9, pitch: 1.0, volume: 1.0, preferredVoice: "es-ES-1"),
        metadata: nil,
        isActive: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let mockExercises = [mockMultipleChoice, mockFillBlank, mockSpeechRecognition]
}
*/

extension ExerciseResult {
    static let mockCorrect = ExerciseResult(
        id: "result-1",
        exerciseId: "ex-1",
        userId: "user-123",
        isCorrect: true,
        score: 10,
        maxScore: 10,
        percentageScore: 100,
        feedback: ExerciseFeedback(
            message: "Perfect! You got it right!",
            level: .excellent,
            suggestions: nil,
            highlights: nil,
            explanation: "Famoso is a direct cognate from 'famous'."
        ),
        correctAnswer: "famoso",
        userAnswer: "famoso",
        partialCredit: false,
        timeSpent: 5,
        hintsUsed: 0,
        attemptNumber: 1,
        createdAt: Date()
    )

    static let mockPartialCredit = ExerciseResult(
        id: "result-2",
        exerciseId: "ex-2",
        userId: "user-123",
        isCorrect: false,
        score: 7,
        maxScore: 10,
        percentageScore: 70,
        feedback: ExerciseFeedback(
            message: "Good attempt! Minor spelling error.",
            level: .acceptable,
            suggestions: ["Check the spelling", "Remember the 'o' at the end"],
            highlights: ["famos"],
            explanation: "The correct spelling is 'famoso' with an 'o' at the end."
        ),
        correctAnswer: "famoso",
        userAnswer: "famos",
        partialCredit: true,
        timeSpent: 12,
        hintsUsed: 1,
        attemptNumber: 1,
        createdAt: Date()
    )
}
