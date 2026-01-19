//
//  Language.swift
//  LanguageLuid
//
//  Language model with CEFR levels matching backend API
//

import Foundation

// MARK: - CEFR Level Enum

enum CEFRLevel: String, Codable, CaseIterable {
    case a1 = "A1"
    case a2 = "A2"
    case b1 = "B1"
    case b2 = "B2"
    case c1 = "C1"
    case c2 = "C2"

    var description: String {
        switch self {
        case .a1:
            return "Beginner: Can understand and use familiar everyday expressions and very basic phrases."
        case .a2:
            return "Elementary: Can understand sentences and frequently used expressions related to areas of immediate relevance."
        case .b1:
            return "Intermediate: Can deal with most situations likely to arise while traveling in an area where the language is spoken."
        case .b2:
            return "Upper Intermediate: Can understand the main ideas of complex text and can interact with a degree of fluency."
        case .c1:
            return "Advanced: Can express ideas fluently and spontaneously without much obvious searching for expressions."
        case .c2:
            return "Proficient: Can understand with ease virtually everything heard or read and express themselves very fluently."
        }
    }

    var shortDescription: String {
        switch self {
        case .a1:
            return "Beginner"
        case .a2:
            return "Elementary"
        case .b1:
            return "Intermediate"
        case .b2:
            return "Upper Intermediate"
        case .c1:
            return "Advanced"
        case .c2:
            return "Proficient"
        }
    }

    var color: String {
        switch self {
        case .a1, .a2:
            return "green"
        case .b1, .b2:
            return "blue"
        case .c1, .c2:
            return "purple"
        }
    }
}

// MARK: - Language Difficulty

enum LanguageDifficulty: String, Codable {
    case beginner
    case intermediate
    case advanced

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Text Direction

enum TextDirection: String, Codable {
    case ltr
    case rtl

    var isRightToLeft: Bool {
        self == .rtl
    }
}

// MARK: - TTS Voice Model
// NOTE: TTSVoice is defined in TTSService.swift to match the API response format

// MARK: - Speech Configuration

struct SpeechConfig: Codable {
    let rate: Double?
    let pitch: Double?
    let volume: Double?
    let preferredVoice: String?

    enum CodingKeys: String, CodingKey {
        case rate, pitch, volume, preferredVoice
    }
}

// MARK: - Language Model

struct Language: Codable, Identifiable, Hashable {
    let id: String
    let code: String
    let name: String
    let nativeName: String
    let direction: TextDirection?  // Optional - not always included in responses
    let flag: String?
    let difficulty: LanguageDifficulty?  // Optional - not always included in responses
    let popularity: Int?  // Optional - not always included in responses
    let isActive: Bool?  // Optional - not always included in responses
    let totalLearners: Int?  // Optional - not always included in responses
    let ttsVoices: [TTSVoice]?
    let speechConfig: SpeechConfig?
    let phonemeSet: [String]?
    let metadata: [String: AnyCodable]?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, code, name, nativeName, direction, flag
        case difficulty, popularity, isActive, totalLearners
        case ttsVoices, speechConfig, phonemeSet, metadata
        case createdAt, updatedAt
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Language, rhs: Language) -> Bool {
        lhs.id == rhs.id
    }

    // Display properties
    var displayName: String {
        "\(flag ?? "") \(name)"
    }

    var learnerCountFormatted: String {
        guard let totalLearners = totalLearners else {
            return "New language"
        }
        if totalLearners >= 1_000_000 {
            return String(format: "%.1fM learners", Double(totalLearners) / 1_000_000)
        } else if totalLearners >= 1_000 {
            return String(format: "%.1fK learners", Double(totalLearners) / 1_000)
        } else {
            return "\(totalLearners) learners"
        }
    }

    var isRightToLeft: Bool {
        direction?.isRightToLeft ?? false
    }
}

// MARK: - Supported Languages

extension Language {
    static let supportedLanguages: [String] = [
        "es", // Spanish
        "fr", // French
        "de", // German
        "it", // Italian
        "pt", // Portuguese
        "ja", // Japanese
        "ko", // Korean
        "zh", // Chinese
        "ar", // Arabic
        "ru", // Russian
        "hi", // Hindi
        "nl", // Dutch
        "sv", // Swedish
        "pl", // Polish
        "tr"  // Turkish
    ]

    static func isSupported(code: String) -> Bool {
        supportedLanguages.contains(code.lowercased())
    }
}

// MARK: - Mock Data for Previews
// TODO: Fix mock data to match current struct definitions
/*
extension Language {
    static let mockSpanish = Language(
        id: "550e8400-e29b-41d4-a716-446655440000",
        code: "es",
        name: "Spanish",
        nativeName: "Español",
        direction: .ltr,
        flag: "🇪🇸",
        difficulty: .beginner,
        popularity: 1,
        isActive: true,
        totalLearners: 125_000,
        ttsVoices: [
            TTSVoice(id: "es-ES-1", name: "Maria", gender: "female", locale: "es-ES", quality: "high"),
            TTSVoice(id: "es-MX-1", name: "Juan", gender: "male", locale: "es-MX", quality: "high")
        ],
        speechConfig: SpeechConfig(rate: 1.0, pitch: 1.0, volume: 1.0, preferredVoice: "es-ES-1"),
        phonemeSet: ["a", "e", "i", "o", "u", "ñ", "ll", "rr"],
        metadata: nil,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let mockFrench = Language(
        id: "550e8400-e29b-41d4-a716-446655440001",
        code: "fr",
        name: "French",
        nativeName: "Français",
        direction: .ltr,
        flag: "🇫🇷",
        difficulty: .intermediate,
        popularity: 2,
        isActive: true,
        totalLearners: 85_000,
        ttsVoices: [
            TTSVoice(id: "fr-FR-1", name: "Céline", gender: "female", locale: "fr-FR", quality: "high")
        ],
        speechConfig: SpeechConfig(rate: 1.0, pitch: 1.0, volume: 1.0, preferredVoice: "fr-FR-1"),
        phonemeSet: ["é", "è", "ê", "à", "ù", "ô", "ç"],
        metadata: nil,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let mockGerman = Language(
        id: "550e8400-e29b-41d4-a716-446655440002",
        code: "de",
        name: "German",
        nativeName: "Deutsch",
        direction: .ltr,
        flag: "🇩🇪",
        difficulty: .intermediate,
        popularity: 3,
        isActive: true,
        totalLearners: 62_000,
        ttsVoices: [
            TTSVoice(id: "de-DE-1", name: "Hans", gender: "male", locale: "de-DE", quality: "high")
        ],
        speechConfig: SpeechConfig(rate: 1.0, pitch: 1.0, volume: 1.0, preferredVoice: "de-DE-1"),
        phonemeSet: ["ä", "ö", "ü", "ß"],
        metadata: nil,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let mockLanguages = [mockSpanish, mockFrench, mockGerman]
}
*/

// MARK: - AnyCodable Helper

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}
