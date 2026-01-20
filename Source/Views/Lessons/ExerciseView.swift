//
//  ExerciseView.swift
//  LanguageLuid
//
//  Exercise renderer supporting all 11 exercise types
//  Handles multiple choice, fill-in-blank, matching, speech, listening, and more
//

import SwiftUI
import AVFoundation

struct ExerciseView: View {
    // MARK: - Properties

    let exercise: Exercise
    let languageCode: String // Language locale (e.g., "es-ES", "fr-FR")
    let onSubmit: (ResponseValue) -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var userResponse: ResponseValue?
    @State private var isAnswerSubmitted = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: LLSpacing.lg) {
            // Exercise Type Badge
            exerciseTypeBadge

            // Prompt
            promptSection

            // Audio Player (if available)
            if exercise.hasAudio {
                audioPlayerSection
            }

            // Exercise Content (based on type)
            exerciseContent

            // Submit Button
            if !isAnswerSubmitted {
                submitButton
            }
        }
    }

    // MARK: - Exercise Type Badge

    private var exerciseTypeBadge: some View {
        HStack(spacing: LLSpacing.xs) {
            Image(systemName: exercise.icon)
                .font(.system(size: 14))

            Text(exercise.displayType)
                .font(LLTypography.caption())
                .fontWeight(.semibold)
        }
        .foregroundColor(LLColors.primary.color(for: colorScheme))
        .padding(.horizontal, LLSpacing.sm)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(LLColors.primary.color(for: colorScheme).opacity(0.15))
        )
    }

    // MARK: - Prompt Section

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: LLSpacing.sm) {
            Text(exercise.prompt)
                .font(LLTypography.h4())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)

            if exercise.points > 0 {
                HStack(spacing: LLSpacing.xs) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(LLColors.warning.color(for: colorScheme))

                    Text("\(exercise.points) points")
                        .font(LLTypography.captionSmall())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
            }
        }
    }

    // MARK: - Audio Player Section

    @ViewBuilder
    private var audioPlayerSection: some View {
        // Use expectedResponse as the text to speak, fallback to empty
        let audioText = exercise.expectedResponse ?? ""

        if !audioText.isEmpty {
            AudioPlayerControl(
                text: audioText,
                languageCode: languageCode,
                showSpeedControl: true,
                isCompact: false
            )
        } else if let audioUrl = exercise.promptAudioUrl {
            // Fallback to placeholder if we have an audio URL
            AudioPlayerView(audioUrl: audioUrl)
        } else {
            EmptyView()
        }
    }

    // MARK: - Exercise Content

    @ViewBuilder
    private var exerciseContent: some View {
        switch exercise.exerciseType {
        case .multipleChoice:
            MultipleChoiceExercise(
                exercise: exercise,
                onSelect: { response in
                    userResponse = .string(response)
                }
            )

        case .fillBlank:
            FillBlankExercise(
                exercise: exercise,
                onTextChange: { text in
                    userResponse = .string(text)
                }
            )

        case .matching:
            MatchingExercise(
                exercise: exercise,
                onMatch: { pairs in
                    userResponse = .object(pairs)
                }
            )

        case .ordering:
            OrderingExercise(
                exercise: exercise,
                onOrder: { items in
                    userResponse = .array(items)
                }
            )

        case .translation:
            TranslationExercise(
                exercise: exercise,
                onTextChange: { text in
                    userResponse = .string(text)
                }
            )

        case .speechRecognition, .speechRepeat:
            SpeechExercise(
                exercise: exercise,
                languageCode: languageCode,
                onRecognize: { text in
                    userResponse = .string(text)
                }
            )

        case .listeningComprehension:
            ListeningExercise(
                exercise: exercise,
                onSelect: { response in
                    userResponse = .string(response)
                }
            )

        case .conversationTurn:
            ConversationExercise(
                exercise: exercise,
                onRespond: { text in
                    userResponse = .string(text)
                }
            )

        case .freeResponse:
            FreeResponseExercise(
                exercise: exercise,
                onTextChange: { text in
                    userResponse = .string(text)
                }
            )

        case .speechResponse:
            SpeechResponseExercise(
                exercise: exercise,
                languageCode: languageCode,
                onRecognize: { text in
                    userResponse = .string(text)
                }
            )
        }
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        LLButton(
            "Check Answer",
            icon: Image(systemName: "checkmark.circle.fill"),
            style: .primary,
            size: .lg,
            isDisabled: userResponse == nil,
            fullWidth: true
        ) {
            if let response = userResponse {
                isAnswerSubmitted = true
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onSubmit(response)
            }
        }
    }
}

// MARK: - Multiple Choice Exercise

private struct MultipleChoiceExercise: View {
    let exercise: Exercise
    let onSelect: (String) -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var selectedOption: String?

    var body: some View {
        VStack(spacing: LLSpacing.sm) {
            ForEach(exercise.options ?? []) { option in
                OptionButton(
                    text: option.text,
                    isSelected: selectedOption == option.id,
                    onTap: {
                        selectedOption = option.id
                        onSelect(option.text)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                )
            }
        }
    }
}

// MARK: - Fill Blank Exercise

private struct FillBlankExercise: View {
    let exercise: Exercise
    let onTextChange: (String) -> Void

    @State private var answer = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: LLSpacing.sm) {
            Text("Type your answer:")
                .font(LLTypography.bodySmall())
                .foregroundColor(LLColors.mutedForeground.adaptive)

            LLTextField(
                "Your answer",
                text: $answer,
                type: .standard
            )
            .focused($isFocused)
            .onChange(of: answer) { _, newValue in
                onTextChange(newValue)
            }
            .onAppear {
                isFocused = true
            }
        }
    }
}

// MARK: - Matching Exercise

private struct MatchingExercise: View {
    let exercise: Exercise
    let onMatch: ([String: String]) -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var matches: [String: String] = [:]
    @State private var leftItems: [String] = []
    @State private var rightItems: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: LLSpacing.md) {
            Text("Drag to match pairs:")
                .font(LLTypography.bodySmall())
                .foregroundColor(LLColors.mutedForeground.adaptive)

            // Placeholder for drag-and-drop implementation
            VStack(spacing: LLSpacing.sm) {
                ForEach(leftItems, id: \.self) { item in
                    HStack {
                        MatchCard(text: item)
                        Image(systemName: "arrow.left.and.right")
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        MatchCard(text: matches[item] ?? "Drop here")
                    }
                }
            }

            Text("Note: Full drag-and-drop support coming in Phase 6")
                .font(LLTypography.captionSmall())
                .foregroundColor(LLColors.warning.color(for: colorScheme))
        }
        .onAppear {
            // Parse items from exercise options
            if let options = exercise.options {
                leftItems = Array(options.prefix(options.count / 2).map { $0.text })
                rightItems = Array(options.suffix(options.count / 2).map { $0.text })
            }
        }
    }
}

// MARK: - Ordering Exercise

private struct OrderingExercise: View {
    let exercise: Exercise
    let onOrder: ([String]) -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var words: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: LLSpacing.md) {
            Text("Tap the words in the correct order:")
                .font(LLTypography.bodySmall())
                .foregroundColor(LLColors.mutedForeground.adaptive)

            // Word chips
            FlowLayout(spacing: LLSpacing.sm) {
                ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                    WordChip(
                        text: word,
                        index: index + 1,
                        onTap: {
                            // Move word to selected area
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    )
                }
            }

            Text("Note: Word ordering will be interactive in Phase 6")
                .font(LLTypography.captionSmall())
                .foregroundColor(LLColors.warning.color(for: colorScheme))
        }
        .onAppear {
            if let options = exercise.options {
                words = options.map { $0.text }.shuffled()
            }
        }
    }
}

// MARK: - Translation Exercise

private struct TranslationExercise: View {
    let exercise: Exercise
    let onTextChange: (String) -> Void

    @State private var translation = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: LLSpacing.sm) {
            Text("Translate to English:")
                .font(LLTypography.bodySmall())
                .foregroundColor(LLColors.mutedForeground.adaptive)

            LLTextField(
                "Type translation",
                text: $translation,
                type: .standard
            )
            .focused($isFocused)
            .onChange(of: translation) { _, newValue in
                onTextChange(newValue)
            }
            .onAppear {
                isFocused = true
            }
        }
    }
}

// MARK: - Speech Exercise

private struct SpeechExercise: View {
    let exercise: Exercise
    let languageCode: String
    let onRecognize: (String) -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: LLSpacing.lg) {
            // Instruction
            Text(exercise.exerciseType == .speechRepeat ? "Tap the microphone and repeat:" : "Speak your answer:")
                .font(LLTypography.bodySmall())
                .foregroundColor(LLColors.mutedForeground.adaptive)

            // Real Speech Recorder with Validation
            if let expectedText = exercise.expectedResponse {
                SpeechRecorderView(
                    lessonId: exercise.lessonId,
                    stepIndex: exercise.order,
                    expectedText: expectedText,
                    languageCode: languageCode,
                    onValidationPassed: { validationResponse in
                        // Pass the transcription back
                        onRecognize(validationResponse.transcription ?? "")
                    }
                )
            } else {
                // Fallback if no expected response
                Text("No expected response configured for this exercise")
                    .font(LLTypography.bodySmall())
                    .foregroundColor(LLColors.warning.color(for: colorScheme))
            }
        }
    }
}

// MARK: - Listening Exercise

private struct ListeningExercise: View {
    let exercise: Exercise
    let onSelect: (String) -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var selectedOption: String?

    var body: some View {
        VStack(spacing: LLSpacing.md) {
            // Audio instruction
            HStack(spacing: LLSpacing.sm) {
                Image(systemName: "ear.fill")
                    .foregroundColor(LLColors.primary.color(for: colorScheme))

                Text("Listen and choose the correct answer:")
                    .font(LLTypography.bodySmall())
                    .foregroundColor(LLColors.mutedForeground.adaptive)
            }

            // Audio player
            if let audioUrl = exercise.promptAudioUrl {
                AudioPlayerView(audioUrl: audioUrl)
            }

            // Options
            VStack(spacing: LLSpacing.sm) {
                ForEach(exercise.options ?? []) { option in
                    OptionButton(
                        text: option.text,
                        isSelected: selectedOption == option.id,
                        onTap: {
                            selectedOption = option.id
                            onSelect(option.text)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Conversation Exercise

private struct ConversationExercise: View {
    let exercise: Exercise
    let onRespond: (String) -> Void

    @State private var response = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: LLSpacing.md) {
            // AI Avatar
            HStack(spacing: LLSpacing.sm) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(LLColors.primary.adaptive)

                Text("AI Conversation Partner")
                    .font(LLTypography.bodySmall())
                    .foregroundColor(LLColors.mutedForeground.adaptive)
            }

            // Response field
            LLTextField(
                "Type your response",
                text: $response,
                type: .standard
            )
            .focused($isFocused)
            .onChange(of: response) { _, newValue in
                onRespond(newValue)
            }
            .onAppear {
                isFocused = true
            }

            Text("Note: AI conversation will be enabled in Phase 6")
                .font(LLTypography.captionSmall())
                .foregroundColor(LLColors.warning.adaptive)
        }
    }
}

// MARK: - Free Response Exercise

private struct FreeResponseExercise: View {
    let exercise: Exercise
    let onTextChange: (String) -> Void

    @State private var response = ""
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: LLSpacing.sm) {
            Text("Write your response:")
                .font(LLTypography.bodySmall())
                .foregroundColor(LLColors.mutedForeground.adaptive)

            TextEditor(text: $response)
                .font(LLTypography.body())
                .foregroundColor(LLColors.foreground.adaptive)
                .padding(LLSpacing.sm)
                .frame(height: 120)
                .background(
                    RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                        .strokeBorder(LLColors.input.color(for: colorScheme), lineWidth: 1)
                )
                .focused($isFocused)
                .onChange(of: response) { _, newValue in
                    onTextChange(newValue)
                }

            Text("\(response.count) characters")
                .font(LLTypography.captionSmall())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - Speech Response Exercise

private struct SpeechResponseExercise: View {
    let exercise: Exercise
    let languageCode: String
    let onRecognize: (String) -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: LLSpacing.lg) {
            Text("Speak your response:")
                .font(LLTypography.bodySmall())
                .foregroundColor(LLColors.mutedForeground.adaptive)

            // Real Speech Recorder with Validation
            if let expectedText = exercise.expectedResponse {
                SpeechRecorderView(
                    lessonId: exercise.lessonId,
                    stepIndex: exercise.order,
                    expectedText: expectedText,
                    languageCode: languageCode,
                    onValidationPassed: { validationResponse in
                        // Pass the transcription back
                        onRecognize(validationResponse.transcription ?? "")
                    }
                )
            } else {
                // Fallback if no expected response
                Text("No expected response configured for this exercise")
                    .font(LLTypography.bodySmall())
                    .foregroundColor(LLColors.warning.color(for: colorScheme))
            }
        }
    }
}

// MARK: - Supporting Components

private struct OptionButton: View {
    let text: String
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(text)
                    .font(LLTypography.body())
                    .foregroundColor(isSelected ? LLColors.primaryForeground.color(for: colorScheme) : LLColors.foreground.color(for: colorScheme))
                    .multilineTextAlignment(.leading)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(LLColors.primaryForeground.color(for: colorScheme))
                }
            }
            .padding(LLSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                    .fill(isSelected ? LLColors.primary.color(for: colorScheme) : LLColors.card.color(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                    .strokeBorder(
                        isSelected ? LLColors.primary.color(for: colorScheme) : LLColors.border.color(for: colorScheme),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct MatchCard: View {
    let text: String

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Text(text)
            .font(LLTypography.bodySmall())
            .foregroundColor(LLColors.foreground.color(for: colorScheme))
            .padding(LLSpacing.sm)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: LLSpacing.radiusSM)
                    .fill(LLColors.muted.color(for: colorScheme))
            )
    }
}

private struct WordChip: View {
    let text: String
    let index: Int
    let onTap: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: LLSpacing.xs) {
                Text("\(index)")
                    .font(LLTypography.captionSmall())
                    .fontWeight(.bold)
                    .foregroundColor(LLColors.primary.color(for: colorScheme))
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(LLColors.primary.color(for: colorScheme).opacity(0.2)))

                Text(text)
                    .font(LLTypography.body())
            }
            .foregroundColor(LLColors.foreground.color(for: colorScheme))
            .padding(.horizontal, LLSpacing.sm)
            .padding(.vertical, LLSpacing.xs)
            .background(
                Capsule()
                    .fill(LLColors.card.color(for: colorScheme))
            )
            .overlay(
                Capsule()
                    .strokeBorder(LLColors.border.color(for: colorScheme), lineWidth: 1)
            )
        }
    }
}

private struct AudioPlayerView: View {
    let audioUrl: String

    @Environment(\.colorScheme) var colorScheme
    @State private var isPlaying = false

    var body: some View {
        HStack {
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(LLColors.primary.color(for: colorScheme))
            }

            VStack(alignment: .leading, spacing: LLSpacing.xs) {
                Text("Audio")
                    .font(LLTypography.bodySmall())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))

                Text("Tap to play")
                    .font(LLTypography.captionSmall())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }

            Spacer()
        }
        .padding(LLSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                .fill(LLColors.muted.color(for: colorScheme).opacity(0.3))
        )
    }

    private func togglePlayback() {
        isPlaying.toggle()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        // TODO: Implement actual audio playback with AVAudioPlayer
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Preview
// TODO: Re-enable after fixing mock data
/*
#Preview("Exercise View - Multiple Choice") {
    ScrollView {
        ExerciseView(
            exercise: Exercise.mockMultipleChoice,
            languageCode: "es-ES",
            onSubmit: { response in
                print("Submitted: \(response)")
            }
        )
        .padding()
    }
}

#Preview("Exercise View - Fill Blank") {
    ScrollView {
        ExerciseView(
            exercise: Exercise.mockFillBlank,
            languageCode: "es-ES",
            onSubmit: { response in
                print("Submitted: \(response)")
            }
        )
        .padding()
    }
}
*/
