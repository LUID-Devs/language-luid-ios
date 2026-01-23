//
//  SpeechRecorderView.swift
//  LanguageLuid
//
//  Main speech recorder view with audio visualization and validation
//  Integrates AudioRecorder, AudioVisualizer, and Speech Validation API
//

import SwiftUI

struct SpeechRecorderView: View {
    // MARK: - Properties

    /// Lesson ID for validation
    let lessonId: String

    /// Step index within the lesson
    let stepIndex: Int

    /// Expected text for validation
    let expectedText: String

    /// Language code (e.g., "es", "fr")
    let languageCode: String

    /// Callback when validation passes
    let onValidationPassed: (SpeechValidationResponse) -> Void

    /// Optional callback when validation fails
    let onValidationFailed: ((SpeechValidationResponse) -> Void)?

    /// Optional callback when validation starts
    let onValidationStarted: (() -> Void)?

    /// Compact mode (smaller UI)
    let isCompact: Bool

    // MARK: - State

    @StateObject private var audioRecorder = AudioRecorder.shared
    @State private var validationService = SpeechValidationService.shared

    @State private var isValidating: Bool = false
    @State private var isSavingProgress: Bool = false
    @State private var validationResult: SpeechValidationResponse?
    @State private var showResult: Bool = false
    @State private var errorMessage: String?
    @State private var showError: Bool = false

    @Environment(\.colorScheme) var colorScheme

    // MARK: - Initialization

    init(
        lessonId: String,
        stepIndex: Int,
        expectedText: String,
        languageCode: String,
        isCompact: Bool = false,
        onValidationPassed: @escaping (SpeechValidationResponse) -> Void,
        onValidationFailed: ((SpeechValidationResponse) -> Void)? = nil,
        onValidationStarted: (() -> Void)? = nil
    ) {
        self.lessonId = lessonId
        self.stepIndex = stepIndex
        self.expectedText = expectedText
        self.languageCode = languageCode
        self.isCompact = isCompact
        self.onValidationPassed = onValidationPassed
        self.onValidationFailed = onValidationFailed
        self.onValidationStarted = onValidationStarted
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: isCompact ? 12 : 20) {
            if !isCompact {
                // Expected text display
                expectedTextSection
            }

            // Audio visualizer
            if audioRecorder.isRecording {
                AudioVisualizerView(
                    audioLevel: audioRecorder.audioLevel,
                    isRecording: audioRecorder.isRecording,
                    barCount: isCompact ? 30 : 40,
                    maxHeight: isCompact ? 60 : 100
                )
                .frame(height: isCompact ? 60 : 100)
                .padding(.horizontal)
            }

            // Recording status
            if audioRecorder.isRecording {
                recordingStatusView
            }

            // Recording controls
            recordingControls

            // Validation and progress saving loading
            if isValidating || isSavingProgress {
                validationLoadingView
            }

            // Error display
            if let error = errorMessage, showError {
                errorView(error)
            }
        }
        .padding(isCompact ? 12 : 20)
        .sheet(isPresented: $showResult) {
            if let result = validationResult {
                NavigationView {
                    ScrollView {
                        SpeechValidationResultView(
                            result: result,
                            onRetry: {
                                showResult = false
                                validationResult = nil
                                // Reset recorder for retry
                                audioRecorder.reset()
                            },
                            onContinue: result.validation.passed ? {
                                // Just dismiss the modal - progress was already saved automatically
                                showResult = false
                            } : nil
                        )
                    }
                    .navigationTitle("Validation Result")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Close") {
                                showResult = false
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Expected Text Section

    private var expectedTextSection: some View {
        VStack(spacing: 8) {
            Label("Say this:", systemImage: "text.bubble")
                .font(.caption)
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

            Text(expectedText)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LLColors.primary.color(for: colorScheme).opacity(0.1))
                )
        }
    }

    // MARK: - Recording Status

    private var recordingStatusView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(LLColors.destructive.color(for: colorScheme))
                    .frame(width: 8, height: 8)
                    .opacity(audioRecorder.isRecording ? 1.0 : 0.3)

                Text("Recording")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
            }

            Text(formattedRecordingTime)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                .monospacedDigit()
        }
    }

    // MARK: - Recording Controls

    private var recordingControls: some View {
        HStack(spacing: 16) {
            if audioRecorder.state == .idle || audioRecorder.state == .stopped {
                // Start Recording Button
                Button(action: startRecording) {
                    VStack(spacing: 8) {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: isCompact ? 40 : 60))
                        Text("Start Recording")
                            .font(isCompact ? .caption : .subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(LLColors.primaryForeground.color(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LLColors.primary.color(for: colorScheme))
                    )
                }
                .buttonStyle(.plain)

            } else if audioRecorder.state == .recording {
                // Stop Recording Button
                Button(action: stopRecording) {
                    VStack(spacing: 8) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: isCompact ? 40 : 60))
                        Text("Stop & Validate")
                            .font(isCompact ? .caption : .subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(LLColors.destructiveForeground.color(for: colorScheme))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LLColors.destructive.color(for: colorScheme))
                    )
                }
                .buttonStyle(.plain)

                // Cancel Button
                Button(action: cancelRecording) {
                    VStack(spacing: 8) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: isCompact ? 32 : 40))
                        Text("Cancel")
                            .font(isCompact ? .caption2 : .caption)
                    }
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Validation Loading

    private var validationLoadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)

            Text(isSavingProgress ? "Saving your progress..." : "Validating your pronunciation...")
                .font(.caption)
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LLColors.card.color(for: colorScheme))
        )
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(LLColors.destructive.color(for: colorScheme))

            Text(message)
                .font(.caption)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            Spacer()

            Button("Dismiss") {
                showError = false
                errorMessage = nil
            }
            .font(.caption2)
            .foregroundColor(LLColors.primary.color(for: colorScheme))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LLColors.destructive.color(for: colorScheme).opacity(0.1))
        )
    }

    // MARK: - Actions

    private func startRecording() {
        Task {
            do {
                try await audioRecorder.startRecording()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func stopRecording() {
        Task {
            do {
                // Stop recording and get file URL
                let audioFileURL = try await audioRecorder.stopRecording()

                // Start validation
                isValidating = true
                showError = false
                errorMessage = nil

                // Notify parent that validation started
                onValidationStarted?()
                NSLog("🔊 [SpeechRecorder] Validation started, notified parent")

                // Validate speech
                let result = try await validationService.validateSpeech(
                    audioFileURL: audioFileURL,
                    lessonId: lessonId,
                    stepIndex: stepIndex,
                    expectedText: expectedText,
                    languageCode: languageCode
                )

                // Stop validation loading
                isValidating = false

                // Store result and show sheet
                validationResult = result
                showResult = true

                // Auto-submit if validation passed
                if result.validation.passed {
                    // Show saving progress state
                    isSavingProgress = true

                    // Call the callback to save progress automatically
                    onValidationPassed(result)

                    // Hide saving state after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isSavingProgress = false
                    }
                } else {
                    // Only call failure callback for failed validations
                    onValidationFailed?(result)
                }

            } catch {
                isValidating = false
                isSavingProgress = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func cancelRecording() {
        audioRecorder.cancelRecording()
    }

    // MARK: - Helpers

    private var formattedRecordingTime: String {
        let minutes = Int(audioRecorder.recordingTime) / 60
        let seconds = Int(audioRecorder.recordingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview("Standard Mode") {
    SpeechRecorderView(
        lessonId: "lesson-1",
        stepIndex: 0,
        expectedText: "Hola, ¿cómo estás?",
        languageCode: "es",
        onValidationPassed: { result in
            print("Validation passed: \(result.validation.score)")
        },
        onValidationFailed: { result in
            print("Validation failed: \(result.validation.score)")
        }
    )
    .padding()
}

#Preview("Compact Mode") {
    SpeechRecorderView(
        lessonId: "lesson-1",
        stepIndex: 0,
        expectedText: "Bonjour",
        languageCode: "fr",
        isCompact: true,
        onValidationPassed: { result in
            print("Validation passed: \(result.validation.score)")
        }
    )
    .padding()
}
