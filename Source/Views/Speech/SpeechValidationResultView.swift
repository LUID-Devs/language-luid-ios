//
//  SpeechValidationResultView.swift
//  LanguageLuid
//
//  Displays speech validation results with feedback and suggestions
//

import SwiftUI

struct SpeechValidationResultView: View {
    // MARK: - Properties

    let result: SpeechValidationResponse
    let onRetry: () -> Void
    let onContinue: (() -> Void)?

    @Environment(\.colorScheme) var colorScheme

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // Score and Rating
            scoreSection

            // Transcription
            if let transcription = result.transcription, !transcription.isEmpty {
                transcriptionSection(transcription)
            }

            // Feedback
            feedbackSection

            // Word Analysis
            if let wordAnalysis = result.wordAnalysis, !wordAnalysis.isEmpty {
                wordAnalysisSection(wordAnalysis)
            }

            // Pronunciation Details
            if let pronunciation = result.pronunciationDetails {
                pronunciationSection(pronunciation)
            }

            // Actions
            actionButtons
        }
        .padding()
    }

    // MARK: - Score Section

    private var scoreSection: some View {
        VStack(spacing: 12) {
            // Rating Icon
            Image(systemName: result.rating.systemImageName)
                .font(.system(size: 60))
                .foregroundColor(ratingColor)

            // Rating Text
            Text(result.rating.displayName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ratingColor)

            // Score
            Text("\(Int(result.overallScore * 100))%")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            // Pass/Fail Badge
            HStack(spacing: 8) {
                Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                Text(result.passed ? "Passed" : "Try Again")
                    .fontWeight(.medium)
            }
            .font(.subheadline)
            .foregroundColor(result.passed ? LLColors.success.color(for: colorScheme) : LLColors.destructive.color(for: colorScheme))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(result.passed ? LLColors.success.color(for: colorScheme).opacity(0.12) : LLColors.destructive.color(for: colorScheme).opacity(0.12))
            )
        }
        .padding(.vertical)
    }

    // MARK: - Transcription Section

    private func transcriptionSection(_ transcription: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("What we heard:", systemImage: "waveform")
                .font(.headline)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            Text(transcription)
                .font(.body)
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LLColors.card.color(for: colorScheme))
                )
        }
    }

    // MARK: - Feedback Section

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main feedback message
            Label("Feedback", systemImage: "message.fill")
                .font(.headline)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            Text(result.feedback.message)
                .font(.body)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LLColors.card.color(for: colorScheme))
                )

            // Suggestions
            if !result.feedback.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggestions:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))

                    ForEach(result.feedback.suggestions, id: \.self) { suggestion in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundColor(LLColors.foreground.color(for: colorScheme))

                            Text(suggestion)
                                .font(.caption)
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LLColors.primary.color(for: colorScheme).opacity(0.05))
                )
            }

            // Encouragement
            if let encouragement = result.feedback.encouragement, !encouragement.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))
                    Text(encouragement)
                        .font(.caption)
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))
                        .italic()
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Word Analysis Section

    private func wordAnalysisSection(_ words: [WordAnalysis]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Word Analysis", systemImage: "text.word.spacing")
                .font(.headline)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(words) { word in
                        wordAnalysisCard(word)
                    }
                }
            }
        }
    }

    private func wordAnalysisCard(_ word: WordAnalysis) -> some View {
        VStack(spacing: 6) {
            // Word
            Text(word.word)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            // Checkmark or X
            Image(systemName: word.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title3)
                .foregroundColor(word.correct ? LLColors.success.color(for: colorScheme) : LLColors.destructive.color(for: colorScheme))

            // Score if available
            if let score = word.score {
                Text("\(Int(score * 100))%")
                    .font(.caption2)
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
        }
        .padding()
        .frame(minWidth: 80)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LLColors.card.color(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    word.correct
                        ? LLColors.success.color(for: colorScheme).opacity(0.3)
                        : LLColors.destructive.color(for: colorScheme).opacity(0.3),
                    lineWidth: 2
                )
        )
    }

    // MARK: - Pronunciation Section

    private func pronunciationSection(_ details: PronunciationDetails) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Pronunciation Metrics", systemImage: "speaker.wave.3.fill")
                .font(.headline)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            VStack(spacing: 10) {
                if let accuracy = details.accuracy {
                    pronunciationMetric(label: "Accuracy", value: accuracy, icon: "target")
                }
                if let fluency = details.fluency {
                    pronunciationMetric(label: "Fluency", value: fluency, icon: "waveform")
                }
                if let prosody = details.prosody {
                    pronunciationMetric(label: "Prosody", value: prosody, icon: "music.note")
                }
                if let completeness = details.completeness {
                    pronunciationMetric(label: "Completeness", value: completeness, icon: "checkmark.circle")
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(LLColors.card.color(for: colorScheme))
            )
        }
    }

    private func pronunciationMetric(label: String, value: Double, icon: String) -> some View {
        HStack {
            // Icon and Label
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(LLColors.primary.color(for: colorScheme))
                Text(label)
                    .font(.caption)
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
            }

            Spacer()

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LLColors.mutedForeground.color(for: colorScheme).opacity(0.2))

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(metricColor(value))
                        .frame(width: geometry.size.width * CGFloat(value))
                }
            }
            .frame(width: 100, height: 8)

            // Percentage
            Text("\(Int(value * 100))%")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                .frame(width: 40, alignment: .trailing)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            if !result.passed && result.canRetry {
                // Retry Button
                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.headline)
                    .foregroundColor(LLColors.primaryForeground.color(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LLColors.primary.color(for: colorScheme))
                    )
                }
                .buttonStyle(.plain)
            }

            if result.passed, let continueAction = onContinue {
                // Continue Button
                Button(action: continueAction) {
                    HStack {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(LLColors.successForeground.color(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LLColors.success.color(for: colorScheme))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helper Methods

    private var ratingColor: Color {
        switch result.rating {
        case .excellent: return LLColors.success.color(for: colorScheme)
        case .good: return LLColors.info.color(for: colorScheme)
        case .acceptable: return LLColors.warning.color(for: colorScheme)
        case .needsImprovement: return LLColors.mutedForeground.color(for: colorScheme)
        case .poor: return LLColors.destructive.color(for: colorScheme)
        }
    }

    private func metricColor(_ value: Double) -> Color {
        if value >= 0.9 {
            return LLColors.foreground.color(for: colorScheme)
        } else if value >= 0.7 {
            return LLColors.info.color(for: colorScheme)
        } else if value >= 0.5 {
            return LLColors.warning.color(for: colorScheme)
        } else {
            return LLColors.destructive.color(for: colorScheme)
        }
    }
}

// MARK: - Preview

#Preview("Excellent Result") {
    ScrollView {
        SpeechValidationResultView(
            result: SpeechValidationResponse(
                success: true,
                passed: true,
                transcription: "Hello, how are you today?",
                overallScore: 0.96,
                rating: .excellent,
                feedback: ValidationFeedback(
                    message: "Outstanding pronunciation! Your clarity and fluency are exceptional.",
                    suggestions: [],
                    encouragement: "Keep up the excellent work!"
                ),
                wordAnalysis: [
                    WordAnalysis(word: "Hello", expected: "Hello", actual: "Hello", correct: true, score: 0.98),
                    WordAnalysis(word: "how", expected: "how", actual: "how", correct: true, score: 0.95),
                    WordAnalysis(word: "are", expected: "are", actual: "are", correct: true, score: 0.96),
                    WordAnalysis(word: "you", expected: "you", actual: "you", correct: true, score: 0.97),
                    WordAnalysis(word: "today", expected: "today", actual: "today", correct: true, score: 0.94)
                ],
                pronunciationDetails: PronunciationDetails(
                    phonemes: nil,
                    accuracy: 0.96,
                    fluency: 0.94,
                    prosody: 0.92,
                    completeness: 1.0
                ),
                attemptCount: 1,
                canRetry: false,
                languageMismatch: false
            ),
            onRetry: {},
            onContinue: {}
        )
    }
}

#Preview("Needs Improvement") {
    ScrollView {
        SpeechValidationResultView(
            result: SpeechValidationResponse(
                success: true,
                passed: false,
                transcription: "Helo, ow ar yu today?",
                overallScore: 0.65,
                rating: .needsImprovement,
                feedback: ValidationFeedback(
                    message: "Your pronunciation needs some work. Focus on clarity and proper enunciation.",
                    suggestions: [
                        "Speak more slowly and clearly",
                        "Practice the 'h' sound at the beginning of words",
                        "Work on vowel sounds in 'how' and 'are'"
                    ],
                    encouragement: "Don't give up! Practice makes perfect."
                ),
                wordAnalysis: [
                    WordAnalysis(word: "Helo", expected: "Hello", actual: "Helo", correct: false, score: 0.75),
                    WordAnalysis(word: "ow", expected: "how", actual: "ow", correct: false, score: 0.60),
                    WordAnalysis(word: "ar", expected: "are", actual: "ar", correct: false, score: 0.55),
                    WordAnalysis(word: "yu", expected: "you", actual: "yu", correct: false, score: 0.65),
                    WordAnalysis(word: "today", expected: "today", actual: "today", correct: true, score: 0.90)
                ],
                pronunciationDetails: PronunciationDetails(
                    phonemes: nil,
                    accuracy: 0.65,
                    fluency: 0.70,
                    prosody: 0.60,
                    completeness: 0.95
                ),
                attemptCount: 2,
                canRetry: true,
                languageMismatch: false
            ),
            onRetry: {},
            onContinue: nil
        )
    }
}
