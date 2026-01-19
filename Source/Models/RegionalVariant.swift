//
//  RegionalVariant.swift
//  LanguageLuid
//
//  Regional variant model matching backend API
//

import Foundation

// MARK: - Formality Level

enum FormalityLevel: String, Codable {
    case formal
    case informal
    case mixed

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Pronoun System

struct PronounSystem: Codable {
    let secondPersonSingularInformal: String?
    let secondPersonSingularFormal: String?
    let secondPersonPluralInformal: String?
    let secondPersonPluralFormal: String?
    let usesVosotros: Bool?
    let usesVos: Bool?

    enum CodingKeys: String, CodingKey {
        case secondPersonSingularInformal, secondPersonSingularFormal
        case secondPersonPluralInformal, secondPersonPluralFormal
        case usesVosotros, usesVos
    }

    var hasVosotros: Bool {
        usesVosotros ?? false
    }

    var hasVos: Bool {
        usesVos ?? false
    }

    var description: String {
        var parts: [String] = []

        if let informal = secondPersonSingularInformal {
            parts.append("Informal: \(informal)")
        }
        if let formal = secondPersonSingularFormal {
            parts.append("Formal: \(formal)")
        }
        if hasVosotros {
            parts.append("Uses vosotros")
        }
        if hasVos {
            parts.append("Uses vos")
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Conjugation Variations

struct ConjugationVariations: Codable {
    let vosotros: TenseConjugations?
    let vos: TenseConjugations?

    struct TenseConjugations: Codable {
        let present: [String: String]?
        let preterite: [String: String]?
        let imperfect: [String: String]?
        let future: [String: String]?
        let conditional: [String: String]?
    }
}

// MARK: - Regional Variant Model

struct RegionalVariant: Codable, Identifiable, Hashable {
    let id: String
    let languageId: String
    let code: String
    let name: String
    let nativeName: String?
    let description: String?
    let countryCode: String?
    let flagEmoji: String?
    let formalityLevel: FormalityLevel
    let pronounSystem: PronounSystem?
    let conjugationVariations: ConjugationVariations?
    let vocabularyVariations: [String: String]?
    let pronunciationNotes: [String]?
    let ttsVoices: [TTSVoice]?
    let isDefault: Bool
    let isActive: Bool
    let displayOrder: Int
    let metadata: [String: AnyCodable]?
    let createdAt: Date?
    let updatedAt: Date?

    // Optional relationships
    let language: Language?

    enum CodingKeys: String, CodingKey {
        case id, languageId, code, name, nativeName, description
        case countryCode, flagEmoji, formalityLevel, pronounSystem
        case conjugationVariations, vocabularyVariations
        case pronunciationNotes, ttsVoices, isDefault, isActive
        case displayOrder, metadata, createdAt, updatedAt, language
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: RegionalVariant, rhs: RegionalVariant) -> Bool {
        lhs.id == rhs.id
    }

    // Computed properties
    var displayName: String {
        if let flag = flagEmoji {
            return "\(flag) \(name)"
        }
        return name
    }

    var fullDisplayName: String {
        if let native = nativeName {
            return "\(displayName) (\(native))"
        }
        return displayName
    }

    var usesVosotros: Bool {
        pronounSystem?.hasVosotros ?? false
    }

    var usesVos: Bool {
        pronounSystem?.hasVos ?? false
    }

    var hasConjugationVariations: Bool {
        conjugationVariations != nil
    }

    var hasVocabularyVariations: Bool {
        !(vocabularyVariations?.isEmpty ?? true)
    }

    var pronunciationNotesFormatted: String {
        guard let notes = pronunciationNotes, !notes.isEmpty else {
            return "Standard pronunciation"
        }
        return notes.joined(separator: "\n• ")
    }

    var availableVoices: [TTSVoice] {
        ttsVoices ?? []
    }

    var hasMultipleVoices: Bool {
        (ttsVoices?.count ?? 0) > 1
    }

    // Get vocabulary word for this variant
    func vocabulary(for englishWord: String) -> String? {
        vocabularyVariations?[englishWord]
    }

    // Get conjugation for verb in this variant
    func conjugation(verb: String, tense: String, person: String) -> String? {
        if person == "vosotros", let vosotros = conjugationVariations?.vosotros {
            switch tense {
            case "present":
                return vosotros.present?[verb]
            case "preterite":
                return vosotros.preterite?[verb]
            case "imperfect":
                return vosotros.imperfect?[verb]
            case "future":
                return vosotros.future?[verb]
            case "conditional":
                return vosotros.conditional?[verb]
            default:
                return nil
            }
        } else if person == "vos", let vos = conjugationVariations?.vos {
            switch tense {
            case "present":
                return vos.present?[verb]
            case "preterite":
                return vos.preterite?[verb]
            case "imperfect":
                return vos.imperfect?[verb]
            case "future":
                return vos.future?[verb]
            case "conditional":
                return vos.conditional?[verb]
            default:
                return nil
            }
        }
        return nil
    }
}

// MARK: - Mock Data for Previews
// TODO: Fix mock data - Language.mockSpanish is unavailable
/*
extension RegionalVariant {
    static let mockSpainSpanish = RegionalVariant(
        id: "990e8400-e29b-41d4-a716-446655440000",
        languageId: Language.mockSpanish.id,
        code: "es-ES",
        name: "Spain Spanish",
        nativeName: "Español de España",
        description: "European Spanish with vosotros form and Castilian pronunciation",
        countryCode: "ES",
        flagEmoji: "🇪🇸",
        formalityLevel: .mixed,
        pronounSystem: PronounSystem(
            secondPersonSingularInformal: "tú",
            secondPersonSingularFormal: "usted",
            secondPersonPluralInformal: "vosotros",
            secondPersonPluralFormal: "ustedes",
            usesVosotros: true,
            usesVos: false
        ),
        conjugationVariations: ConjugationVariations(
            vosotros: ConjugationVariations.TenseConjugations(
                present: [
                    "hablar": "habláis",
                    "comer": "coméis",
                    "vivir": "vivís"
                ],
                preterite: [
                    "hablar": "hablasteis",
                    "comer": "comisteis",
                    "vivir": "vivisteis"
                ],
                imperfect: nil,
                future: nil,
                conditional: nil
            ),
            vos: nil
        ),
        vocabularyVariations: [
            "car": "coche",
            "computer": "ordenador",
            "apartment": "piso",
            "mobile": "móvil",
            "juice": "zumo"
        ],
        pronunciationNotes: [
            "Distinction between 'c/z' (theta sound) and 's'",
            "Aspiration of 's' at end of syllables",
            "Clear pronunciation of 'd' at end of words"
        ],
        ttsVoices: [
            TTSVoice(id: "es-ES-1", name: "María", gender: "female", locale: "es-ES", quality: "high"),
            TTSVoice(id: "es-ES-2", name: "Jorge", gender: "male", locale: "es-ES", quality: "high")
        ],
        isDefault: true,
        isActive: true,
        displayOrder: 1,
        metadata: nil,
        createdAt: Date(),
        updatedAt: Date(),
        language: nil
    )

    static let mockMexicanSpanish = RegionalVariant(
        id: "990e8400-e29b-41d4-a716-446655440001",
        languageId: Language.mockSpanish.id,
        code: "es-MX",
        name: "Mexican Spanish",
        nativeName: "Español mexicano",
        description: "Mexican Spanish with ustedes instead of vosotros and seseo pronunciation",
        countryCode: "MX",
        flagEmoji: "🇲🇽",
        formalityLevel: .mixed,
        pronounSystem: PronounSystem(
            secondPersonSingularInformal: "tú",
            secondPersonSingularFormal: "usted",
            secondPersonPluralInformal: "ustedes",
            secondPersonPluralFormal: "ustedes",
            usesVosotros: false,
            usesVos: false
        ),
        conjugationVariations: nil,
        vocabularyVariations: [
            "car": "carro",
            "computer": "computadora",
            "apartment": "departamento",
            "mobile": "celular",
            "juice": "jugo"
        ],
        pronunciationNotes: [
            "No distinction between 'c/z' and 's' (seseo)",
            "Clear pronunciation of all consonants",
            "Neutral intonation patterns"
        ],
        ttsVoices: [
            TTSVoice(id: "es-MX-1", name: "Mia", gender: "female", locale: "es-MX", quality: "high"),
            TTSVoice(id: "es-MX-2", name: "Diego", gender: "male", locale: "es-MX", quality: "high")
        ],
        isDefault: false,
        isActive: true,
        displayOrder: 2,
        metadata: nil,
        createdAt: Date(),
        updatedAt: Date(),
        language: nil
    )

    static let mockArgentineSpanish = RegionalVariant(
        id: "990e8400-e29b-41d4-a716-446655440002",
        languageId: Language.mockSpanish.id,
        code: "es-AR",
        name: "Argentine Spanish",
        nativeName: "Español argentino",
        description: "Argentine Spanish with vos form and distinctive River Plate pronunciation",
        countryCode: "AR",
        flagEmoji: "🇦🇷",
        formalityLevel: .informal,
        pronounSystem: PronounSystem(
            secondPersonSingularInformal: "vos",
            secondPersonSingularFormal: "usted",
            secondPersonPluralInformal: "ustedes",
            secondPersonPluralFormal: "ustedes",
            usesVosotros: false,
            usesVos: true
        ),
        conjugationVariations: ConjugationVariations(
            vosotros: nil,
            vos: ConjugationVariations.TenseConjugations(
                present: [
                    "hablar": "hablás",
                    "comer": "comés",
                    "vivir": "vivís"
                ],
                preterite: nil,
                imperfect: nil,
                future: nil,
                conditional: nil
            )
        ),
        vocabularyVariations: [
            "car": "auto",
            "computer": "computadora",
            "apartment": "departamento",
            "mobile": "celular",
            "juice": "jugo"
        ],
        pronunciationNotes: [
            "Yeísmo: 'll' and 'y' pronounced as 'sh'",
            "Italian-influenced intonation",
            "Strong aspiration of 's' at end of syllables"
        ],
        ttsVoices: [
            TTSVoice(id: "es-AR-1", name: "Elena", gender: "female", locale: "es-AR", quality: "high")
        ],
        isDefault: false,
        isActive: true,
        displayOrder: 3,
        metadata: nil,
        createdAt: Date(),
        updatedAt: Date(),
        language: nil
    )

    static let mockVariants = [
        mockSpainSpanish,
        mockMexicanSpanish,
        mockArgentineSpanish
    ]
}
*/
