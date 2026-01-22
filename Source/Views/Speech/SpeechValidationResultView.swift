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

    // Computed rating from scoreLevel
    private var rating: ValidationRating {
        ValidationRating(from: result.validation.scoreLevel)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // Score and Rating
            scoreSection

            // Transcription
            if !result.validation.transcription.isEmpty {
                transcriptionSection(result.validation.transcription, expected: result.validation.expectedText)
            }

            // Feedback
            feedbackSection

            // Word Analysis
            if let wordAnalysis = result.details.wordAnalysis {
                wordAnalysisSection(wordAnalysis)
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
            Image(systemName: rating.systemImageName)
                .font(.system(size: 60))
                .foregroundColor(ratingColor)

            // Rating Text
            Text(rating.displayName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ratingColor)

            // Score
            Text("\(result.validation.scorePercentage)%")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            // Pass/Fail Badge
            HStack(spacing: 8) {
                Image(systemName: result.validation.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                Text(result.validation.passed ? "Passed" : "Try Again")
                    .fontWeight(.medium)
            }
            .font(.subheadline)
            .foregroundColor(result.validation.passed ? LLColors.success.color(for: colorScheme) : LLColors.destructive.color(for: colorScheme))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(result.validation.passed ? LLColors.success.color(for: colorScheme).opacity(0.12) : LLColors.destructive.color(for: colorScheme).opacity(0.12))
            )
        }
        .padding(.vertical)
    }

    // MARK: - Transcription Section

    private func transcriptionSection(_ transcription: String, expected: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("What we heard:", systemImage: "waveform")
                .font(.headline)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("You said:")
                        .font(.caption)
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    Spacer()
                }
                Text(transcription)
                    .font(.body)
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(LLColors.card.color(for: colorScheme))
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Expected:")
                        .font(.caption)
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    Spacer()
                }
                Text(expected)
                    .font(.body)
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(LLColors.muted.color(for: colorScheme).opacity(0.2))
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

            Text(result.feedback.overall)
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
                                .foregroundColor(LLColors.primary.color(for: colorScheme))

                            Text(suggestion)
                                .font(.caption)
                                .foregroundColor(LLColors.foreground.color(for: colorScheme))
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

    private func wordAnalysisSection(_ analysis: WordAnalysisDetails) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Word Analysis", systemImage: "text.word.spacing")
                .font(.headline)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            // Stats
            HStack(spacing: 20) {
                statCard(label: "Accuracy", value: "\(Int(analysis.accuracy * 100))%", color: LLColors.success.color(for: colorScheme))
                statCard(label: "Matched", value: "\(analysis.matchCount)/\(analysis.totalExpected)", color: LLColors.info.color(for: colorScheme))
            }

            // Matches
            if !analysis.matches.isEmpty {
                wordListSection(title: "✓ Correct", words: analysis.matches, color: LLColors.success.color(for: colorScheme))
            }

            // Missing
            if !analysis.missing.isEmpty {
                wordListSection(title: "⚠ Missing", words: analysis.missing, color: LLColors.warning.color(for: colorScheme))
            }

            // Extra
            if !analysis.extra.isEmpty {
                wordListSection(title: "➕ Extra", words: analysis.extra, color: LLColors.info.color(for: colorScheme))
            }

            // Incorrect
            if !analysis.incorrect.isEmpty {
                wordListSection(title: "✗ Incorrect", words: analysis.incorrect, color: LLColors.destructive.color(for: colorScheme))
            }
        }
    }

    private func statCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LLColors.card.color(for: colorScheme))
        )
    }

    private func wordListSection(title: String, words: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(words, id: \.self) { word in
                        Text(word)
                            .font(.caption)
                            .foregroundColor(LLColors.foreground.color(for: colorScheme))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(color.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(color.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LLColors.card.color(for: colorScheme))
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            if !result.validation.passed {
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

            if result.validation.passed, let continueAction = onContinue {
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
        switch rating {
        case .excellent: return LLColors.success.color(for: colorScheme)
        case .good: return LLColors.info.color(for: colorScheme)
        case .acceptable: return LLColors.warning.color(for: colorScheme)
        case .needsImprovement: return LLColors.mutedForeground.color(for: colorScheme)
        case .poor: return LLColors.destructive.color(for: colorScheme)
        }
    }
}
