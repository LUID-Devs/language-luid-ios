//
//  LessonPhaseView.swift
//  LanguageLuid
//
//  Active lesson player for one phase with exercise navigation
//  Shows progress, timer, score, and phase completion
//

import SwiftUI
import os.log
import NaturalLanguage

struct LessonPhaseView: View {
    // MARK: - Properties

    let roadmapId: String
    let lessonId: String
    let phase: LessonPhaseDefinition
    @Binding var selectedPhase: LessonPhaseDefinition?

    @StateObject private var viewModel = LessonViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var currentExerciseIndex = 0
    @State private var completedSteps: [Int] = []
    @State private var startTime = Date()
    @State private var elapsedSeconds = 0
    @State private var score = 0
    @State private var totalScore = 0
    @State private var correctAnswers = 0
    @State private var showExitConfirmation = false
    @State private var showPhaseCompletion = false
    @State private var showFeedback = false
    @State private var isAnswerCorrect = false
    @State private var feedbackMessage = ""
    @State private var showConfetti = false
    @State private var isLoadingProgress = true
    @State private var exercisesLoadedSuccessfully = false
    @State private var isSpeechValidationInProgress = false
    @State private var exerciseResetCounter = 0 // Increments to force ExerciseView reset

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Body

    var body: some View {
        ZStack {
            LLColors.background.color(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Bar
                topBar

                Divider()
                    .background(LLColors.border.color(for: colorScheme))

                // Progress Bar
                progressBar

                // Exercise Container
                if viewModel.isLoading {
                    loadingState
                } else if !exercisesLoadedSuccessfully {
                    // Still loading initial data
                    loadingState
                } else if !viewModel.exercises.isEmpty, let exercise = currentExercise {
                    exerciseContainer(exercise)
                } else {
                    emptyState
                }

                Spacer(minLength: 0)
            }

            // Bottom Navigation - Positioned absolutely at bottom
            VStack {
                Spacer()
                bottomNavigation
            }

            // Feedback Overlay (positioned to not cover bottom nav)
            if showFeedback {
                feedbackOverlay
            }

            // Phase Completion
            if showPhaseCompletion {
                phaseCompletionOverlay
            }

            // Confetti
            if showConfetti {
                ConfettiView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Phase \(phase.phaseNumber)")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showExitConfirmation = true }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundColor(LLColors.destructive.color(for: colorScheme))
                        .symbolRenderingMode(.hierarchical)
                }
                .accessibilityLabel("Exit phase")
                .accessibilityHint("Double tap to exit the current lesson phase")
            }
        }
        .onDisappear {
            // CRITICAL: Use detached task to ensure progress saves even if parent view dismisses
            // Capture values before the closure to avoid capturing @State wrappers
            let currentStep = currentExerciseIndex
            let completed = completedSteps
            let loaded = exercisesLoadedSuccessfully
            let roadmap = roadmapId
            let lesson = lessonId
            let phaseNum = phase.phaseNumber

            Task.detached { [weak viewModel] in
                guard let viewModel = viewModel, loaded else {
                    return
                }

                // Check exercises count on main actor
                let hasExercises = await MainActor.run { !viewModel.exercises.isEmpty }
                guard hasExercises else {
                    return
                }

                await viewModel.saveStepProgress(
                    roadmapId: roadmap,
                    lessonId: lesson,
                    phaseNumber: phaseNum,
                    currentStep: currentStep,
                    completedSteps: completed
                )
            }
        }
        .task(id: selectedPhase?.id) {
            // CRITICAL: This triggers whenever selectedPhase.id changes (Phase 1 → Phase 2)
            // Automatically resets and reloads everything
            guard let currentPhase = selectedPhase else {
                return
            }

            // Reset all state variables
            currentExerciseIndex = 0
            completedSteps = []
            score = 0
            correctAnswers = 0
            elapsedSeconds = 0
            startTime = Date()
            exercisesLoadedSuccessfully = false
            viewModel.exerciseResult = nil
            showFeedback = false
            showPhaseCompletion = false
            showConfetti = false

            // Load exercises BEFORE restoring progress
            await loadExercises(for: currentPhase)

            await loadAndRestoreProgress(for: currentPhase)
        }
        .onReceive(timer) { _ in
            // Stop timer when phase is completed or when showing completion overlay
            guard !showPhaseCompletion else { return }
            elapsedSeconds += 1
        }
        .confirmationDialog("Exit Phase", isPresented: $showExitConfirmation, titleVisibility: .visible) {
            Button("Keep Learning", role: .cancel) {}
            Button("Exit", role: .destructive) {
                // Capture values before the task closure
                let currentStep = currentExerciseIndex
                let completed = completedSteps
                let loaded = exercisesLoadedSuccessfully
                let roadmap = roadmapId
                let lesson = lessonId
                let phaseNum = phase.phaseNumber

                Task {
                    guard loaded, !viewModel.exercises.isEmpty else {
                        dismiss()
                        return
                    }

                    await viewModel.saveStepProgress(
                        roadmapId: roadmap,
                        lessonId: lesson,
                        phaseNumber: phaseNum,
                        currentStep: currentStep,
                        completedSteps: completed
                    )
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to exit? Your progress will be saved.")
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: LLSpacing.md) {
            // Phase Indicator
            HStack(spacing: LLSpacing.xs) {
                Image(systemName: phase.icon)
                    .font(.system(size: 16))
                Text("Phase \(phase.phaseNumber)")
                    .font(LLTypography.bodySmall())
                    .fontWeight(.semibold)
            }
            .foregroundColor(LLColors.primary.color(for: colorScheme))

            Spacer()

            // Timer
            HStack(spacing: LLSpacing.xs) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 14))
                Text(timeFormatted)
                    .font(LLTypography.bodySmall())
                    .fontWeight(.medium)
                    .monospacedDigit()
            }
            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

            // Score
            HStack(spacing: LLSpacing.xs) {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundColor(LLColors.warning.color(for: colorScheme))
                Text("\(score)")
                    .font(LLTypography.bodySmall())
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
            .foregroundColor(LLColors.foreground.color(for: colorScheme))
        }
        .padding(LLSpacing.md)
        .background(LLColors.card.color(for: colorScheme))
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(LLColors.muted.color(for: colorScheme))
                    .frame(height: 4)

                Rectangle()
                    .fill(LLColors.primary.color(for: colorScheme))
                    .frame(width: geometry.size.width * exerciseProgress, height: 4)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: exerciseProgress)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Exercise Container

    private func exerciseContainer(_ exercise: Exercise) -> some View {
        ScrollView {
            VStack(spacing: LLSpacing.lg) {
                // Exercise Counter
                HStack {
                    Text("Question \(currentExerciseIndex + 1) of \(viewModel.exercises.count)")
                        .font(LLTypography.bodySmall())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                    Spacer()
                }
                .padding(.horizontal, LLSpacing.md)
                .padding(.top, LLSpacing.md)

                // Exercise View
                ExerciseView(
                    exercise: exercise,
                    languageCode: detectLanguageForExercise(exercise),
                    onSubmit: { response in
                        submitExercise(response)
                    },
                    onSpeechValidationStarted: {
                        isSpeechValidationInProgress = true
                    }
                )
                .id("\(exercise.id)-\(exerciseResetCounter)") // Force recreation when exercise changes or counter increments
                .padding(.horizontal, LLSpacing.md)
            }
            .padding(.bottom, 100) // Space for bottom navigation
        }
    }

    // MARK: - Bottom Navigation

    private var bottomNavigation: some View {
        let hasResult = viewModel.exerciseResult != nil
        let isCorrectAnswer = viewModel.exerciseResult?.isCorrect ?? false

        return VStack(spacing: 0) {
            HStack(spacing: LLSpacing.md) {
                // Previous Button
                LLButton(
                    "Previous",
                    icon: Image(systemName: "chevron.left"),
                    style: .outline,
                    size: .md,
                    isDisabled: !hasPreviousExercise
                ) {
                    previousExercise()
                }

                // Skip Button
                LLButton(
                    "Skip",
                    style: .ghost,
                    size: .md
                ) {
                    skipExercise()
                }

                Spacer()

                // Check/Next Button - Only show Next if answer is correct
                if hasResult && isCorrectAnswer {
                    let buttonLabel = hasNextExercise ? "Next" : "Complete"
                    LLButton(
                        buttonLabel,
                        icon: Image(systemName: hasNextExercise ? "chevron.right" : "checkmark"),
                        style: .primary,
                        size: .md
                    ) {
                        nextExerciseOrComplete()
                    }
                } else {
                    Text("")
                        .font(.caption)
                }
            }
            .padding(LLSpacing.md)
            .background(
                LLColors.card.color(for: colorScheme)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
            )
        }
        .background(
            LLColors.card.color(for: colorScheme)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Feedback Overlay

    private var feedbackOverlay: some View {
        let iconColor = isAnswerCorrect ? LLColors.success.color(for: colorScheme) : LLColors.destructive.color(for: colorScheme)
        let iconName = isAnswerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"

        return GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top spacer
                Spacer()
                    .frame(height: geometry.size.height * 0.15)

                // Feedback card in center
                LLCard(style: .elevated, padding: .lg) {
                    VStack(spacing: LLSpacing.md) {
                        // Icon
                        Image(systemName: iconName)
                            .font(.system(size: 48))
                            .foregroundColor(iconColor)
                            .scaleEffect(showFeedback ? 1 : 0.5)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showFeedback)

                        // Message
                        Text(feedbackMessage)
                            .font(LLTypography.h4())
                            .foregroundColor(LLColors.foreground.color(for: colorScheme))
                            .multilineTextAlignment(.center)

                        // Explanation
                        if let result = viewModel.exerciseResult {
                            if let explanation = result.feedback?.explanation ?? result.explanation {
                                Text(explanation)
                                    .font(LLTypography.bodySmall())
                                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                    .multilineTextAlignment(.center)
                            }

                            // Points Earned
                            let earnedPoints = result.points ?? Int(result.score)
                            HStack(spacing: LLSpacing.xs) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(LLColors.warning.color(for: colorScheme))
                                Text("+\(earnedPoints) XP")
                                    .font(LLTypography.body())
                                    .fontWeight(.semibold)
                                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
                            }
                        }
                    }
                }
                .padding(.horizontal, LLSpacing.lg)
                .transition(.move(edge: .bottom).combined(with: .opacity))

                // Bottom spacer (leaves room for bottom navigation)
                Spacer()
                    .frame(height: geometry.size.height * 0.25)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Color.black.opacity(0.3)
                    .onTapGesture {
                        dismissFeedback()
                    }
            )
        }
        .allowsHitTesting(true)
    }

    // MARK: - Phase Completion Overlay

    private var phaseCompletionOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            LLCard(style: .elevated, padding: .lg) {
                VStack(spacing: LLSpacing.lg) {
                    // Trophy Icon
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 64))
                        .foregroundColor(LLColors.warning.color(for: colorScheme))
                        .scaleEffect(showPhaseCompletion ? 1 : 0.5)
                        .rotationEffect(.degrees(showPhaseCompletion ? 0 : -180))
                        .animation(.spring(response: 0.6, dampingFraction: 0.5), value: showPhaseCompletion)

                    // Title
                    Text("Phase \(phase.phaseNumber) Complete!")
                        .font(LLTypography.h2())
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))

                    // Auto-navigation message (matches frontend toast)
                    if phase.phaseNumber < 4 {
                        HStack(spacing: LLSpacing.xs) {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(LLColors.primary.color(for: colorScheme))
                            Text("Moving to Phase \(phase.phaseNumber + 1)...")
                                .font(LLTypography.body())
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }
                        .padding(.vertical, LLSpacing.xs)
                    }

                    Divider()

                    // Stats
                    VStack(spacing: LLSpacing.md) {
                        StatRow(label: "Score", value: "\(score) XP", icon: "star.fill")
                        StatRow(label: "Accuracy", value: accuracyFormatted, icon: "target")
                        StatRow(label: "Time", value: timeFormatted, icon: "clock.fill")
                        StatRow(label: "XP Earned", value: "+\(score)", icon: "sparkles")
                    }
                }
            }
            .padding(LLSpacing.xl)
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Loading & Empty States

    private var loadingState: some View {
        VStack(spacing: LLSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(LLColors.primary.color(for: colorScheme))

            Text("Loading exercises...")
                .font(LLTypography.body())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: LLSpacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(LLColors.warning.color(for: colorScheme))

            Text("No Exercises Available")
                .font(LLTypography.h3())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helper Properties

    private var currentExercise: Exercise? {
        guard currentExerciseIndex < viewModel.exercises.count else { return nil }
        return viewModel.exercises[currentExerciseIndex]
    }

    /// Check if there's a next exercise (based on VIEW's currentExerciseIndex, not ViewModel's)
    private var hasNextExercise: Bool {
        currentExerciseIndex < viewModel.exercises.count - 1
    }

    /// Check if there's a previous exercise (based on VIEW's currentExerciseIndex)
    private var hasPreviousExercise: Bool {
        currentExerciseIndex > 0
    }

    private var exerciseProgress: Double {
        guard !viewModel.exercises.isEmpty else { return 0 }
        // Use completion-based progress (matching frontend behavior)
        // Shows how many exercises have been successfully completed, not which question you're on
        let progress = Double(completedSteps.count) / Double(viewModel.exercises.count)
        return progress
    }

    private var timeFormatted: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var accuracyFormatted: String {
        guard !viewModel.exercises.isEmpty else { return "0%" }
        let accuracy = (Double(correctAnswers) / Double(viewModel.exercises.count)) * 100
        return String(format: "%.0f%%", accuracy)
    }

    /// Get language locale for exercise TTS
    /// PRIMARY: Uses user's target language (the language they're learning)
    /// FALLBACK: Only detects from text if user profile is unavailable
    private func detectLanguageForExercise(_ exercise: Exercise) -> String {
        let logger = OSLog(subsystem: "com.luid.languageluid", category: "TTS")

        // PRIMARY: Use user's target language (the language they're learning)
        // This is correct for most cases - if user is learning Spanish, all lessons should use Spanish TTS
        if let targetLanguage = authViewModel.currentUser?.targetLanguage {
            let locale = mapLanguageToLocale(targetLanguage)
            os_log("🎤 TTS Language: Using user.targetLanguage='%{public}@' → locale='%{public}@'",
                   log: logger, type: .info, targetLanguage, locale)
            return locale
        }

        // FALLBACK: Try to detect language from exercise text
        // This helps when user profile is not available
        // Note: Detection doesn't work well for cognates (words that are the same in multiple languages)
        os_log("⚠️ TTS: No targetLanguage in user profile, attempting text detection",
               log: logger, type: .info)

        // Priority order for text to analyze:
        // 1. expectedResponse (target language text for speech/audio exercises)
        // 2. options.first (for multiple choice - first option is usually in target language)
        // 3. prompt (fallback)

        var textToDetect: String? = nil

        if let expectedResponse = exercise.expectedResponse, !expectedResponse.isEmpty {
            textToDetect = expectedResponse
        } else if let options = exercise.options, !options.isEmpty, let firstOption = options.first {
            textToDetect = firstOption.text
        } else if !exercise.prompt.isEmpty {
            textToDetect = exercise.prompt
        }

        if let text = textToDetect {
            let recognizer = NLLanguageRecognizer()
            recognizer.processString(text)

            if let detectedLanguage = recognizer.dominantLanguage {
                let langCode = detectedLanguage.rawValue
                let locale = mapLanguageToLocale(langCode)
                os_log("🔍 TTS: Detected language '%{public}@' from text → locale='%{public}@'",
                       log: logger, type: .info, langCode, locale)
                return locale
            }
        }

        // ULTIMATE FALLBACK: Use device locale
        os_log("⚠️ TTS: All language detection methods failed, using device locale",
               log: logger, type: .error)
        let deviceLang = Locale.current.language.languageCode?.identifier ?? "en"
        let locale = mapLanguageToLocale(deviceLang)
        os_log("🎤 TTS: Using device locale → '%{public}@'", log: logger, type: .info, locale)
        return locale
    }

    /// Map language code to primary TTS locale
    private func mapLanguageToLocale(_ languageCode: String) -> String {
        let localeMap: [String: String] = [
            "es": "es-ES", "spa": "es-ES",
            "fr": "fr-FR", "fra": "fr-FR",
            "de": "de-DE", "deu": "de-DE",
            "it": "it-IT", "ita": "it-IT",
            "pt": "pt-PT", "por": "pt-PT",
            "ja": "ja-JP", "jpn": "ja-JP",
            "ko": "ko-KR", "kor": "ko-KR",
            "zh": "zh-CN", "zho": "zh-CN",
            "ar": "ar-SA", "ara": "ar-SA",
            "ru": "ru-RU", "rus": "ru-RU",
            "hi": "hi-IN", "hin": "hi-IN",
            "nl": "nl-NL", "nld": "nl-NL",
            "sv": "sv-SE", "swe": "sv-SE",
            "pl": "pl-PL", "pol": "pl-PL",
            "tr": "tr-TR", "tur": "tr-TR",
            "en": "en-US", "eng": "en-US"
        ]

        let code = languageCode.lowercased()
        if let mapped = localeMap[code] {
            return mapped
        } else if code.count == 2 {
            // Fallback pattern for 2-letter codes
            return "\(code)-\(code.uppercased())"
        } else {
            // Default to English
            return "en-US"
        }
    }

    // MARK: - Actions

    private func loadExercises(for currentPhase: LessonPhaseDefinition) async {
        await viewModel.loadExercises(
            roadmapId: roadmapId,
            lessonId: lessonId,
            phaseNumber: currentPhase.phaseNumber
        )

        if !viewModel.exercises.isEmpty {
            exercisesLoadedSuccessfully = true
        }

        totalScore = viewModel.exercises.reduce(0) { $0 + $1.points }

        // DEBUG: Log exercises and their points
        NSLog("📚 LOADED \(viewModel.exercises.count) EXERCISES:")
        for (index, ex) in viewModel.exercises.enumerated() {
            NSLog("   Exercise \(index + 1): \(ex.exerciseType.displayName) - Points: \(ex.points)")
        }
        NSLog("   Total possible score: \(totalScore)")
    }

    private func loadAndRestoreProgress(for currentPhase: LessonPhaseDefinition) async {
        // Load step progress from backend
        await viewModel.loadStepProgress(
            roadmapId: roadmapId,
            lessonId: lessonId,
            phaseNumber: currentPhase.phaseNumber
        )

        // Restore position from progress
        if let progress = viewModel.phaseStepProgress {
            let restoredStep = progress.currentStep ?? 0
            let restoredCompleted = progress.completedSteps ?? []

            // Clamp to valid range
            let validStep = max(0, min(restoredStep, viewModel.exercises.count - 1))

            // Recalculate score based on completed exercises
            var restoredScore = 0
            var restoredCorrectAnswers = 0
            for stepIndex in restoredCompleted {
                guard stepIndex < viewModel.exercises.count else { continue }
                let exercise = viewModel.exercises[stepIndex]
                restoredScore += exercise.points
                restoredCorrectAnswers += 1
            }

            DispatchQueue.main.async {
                self.currentExerciseIndex = validStep
                self.completedSteps = restoredCompleted
                self.score = restoredScore
                self.correctAnswers = restoredCorrectAnswers
                self.isLoadingProgress = false
            }
        } else {
            DispatchQueue.main.async {
                self.isLoadingProgress = false
            }
        }
    }

    private func saveCurrentProgress() async {
        // Don't save if exercises never loaded successfully
        guard exercisesLoadedSuccessfully else {
            return
        }

        // Don't save if no exercises in viewModel
        guard !viewModel.exercises.isEmpty else {
            return
        }

        guard let currentPhase = selectedPhase else {
            return
        }

        // Check if task is cancelled before saving
        guard !Task.isCancelled else {
            // Capture values to avoid @State wrapper issues
            let currentStep = currentExerciseIndex
            let completed = completedSteps
            let roadmap = roadmapId
            let lesson = lessonId
            let phaseNum = currentPhase.phaseNumber

            // Use detached task to complete the save even if parent is cancelled
            await Task.detached { [weak viewModel] in
                guard let viewModel = viewModel else { return }
                await viewModel.saveStepProgress(
                    roadmapId: roadmap,
                    lessonId: lesson,
                    phaseNumber: phaseNum,
                    currentStep: currentStep,
                    completedSteps: completed
                )
            }.value
            return
        }

        await viewModel.saveStepProgress(
            roadmapId: roadmapId,
            lessonId: lessonId,
            phaseNumber: currentPhase.phaseNumber,
            currentStep: currentExerciseIndex,
            completedSteps: completedSteps
        )
    }

    private func submitExercise(_ response: ResponseValue) {
        Task {
            // Ensure flag is always cleared, even if an error occurs
            defer {
                isSpeechValidationInProgress = false
            }

            guard let exercise = currentExercise else {
                return
            }

            // Handle ordering exercises with client-side validation (like frontend does)
            if exercise.exerciseType == .ordering {
                // Extract user's answer array
                guard case .array(let userWords) = response else {
                    return
                }

                // Build user's sentence
                let userSentence = userWords.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)

                // Get correct answer
                let correctSentence = (exercise.expectedResponse ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

                // Compare (exact match like frontend)
                let isCorrect = userSentence == correctSentence

                // Create local result (matching ExerciseResult structure)
                let localResult = ExerciseResult(
                    isCorrect: isCorrect,
                    score: isCorrect ? Double(exercise.points) : 0.0,
                    partialCredit: false,
                    correctAnswer: correctSentence,
                    explanation: isCorrect ? "Perfect! You arranged the words correctly." : "Not quite right. The correct answer is: \"\(correctSentence)\"",
                    points: isCorrect ? exercise.points : 0,
                    id: nil,
                    exerciseId: exercise.id,
                    userId: nil,
                    maxScore: Double(exercise.points),
                    percentageScore: isCorrect ? 100 : 0,
                    feedback: ExerciseFeedback(
                        message: isCorrect ? "Correct!" : "Not quite right",
                        level: isCorrect ? .excellent : .poor,
                        suggestions: nil,
                        highlights: nil,
                        explanation: nil
                    ),
                    userAnswer: userSentence,
                    timeSpent: nil,
                    hintsUsed: nil,
                    attemptNumber: nil,
                    createdAt: nil
                )

                // Set result on viewModel so UI can access it
                await MainActor.run {
                    viewModel.exerciseResult = localResult
                }
            } else {
                // All other exercise types: submit to backend
                await viewModel.submitExercise(
                    roadmapId: roadmapId,
                    lessonId: lessonId,
                    exerciseId: exercise.id,
                    responseValue: response
                )
            }

            if let result = viewModel.exerciseResult {
                isAnswerCorrect = result.isCorrect
                // Use feedback.message if available, otherwise use explanation, otherwise use a default message
                feedbackMessage = result.feedback?.message ?? result.explanation ?? (result.isCorrect ? "Correct!" : "Incorrect")

                if result.isCorrect {
                    // Only add points if this exercise hasn't been completed yet
                    // This prevents score from exceeding totalScore when retrying exercises
                    let alreadyCompleted = completedSteps.contains(currentExerciseIndex)
                    if !alreadyCompleted {
                        let earnedPoints = result.points ?? Int(result.score)

                        // DEBUG: Log scoring details
                        NSLog("🎯 SCORING DEBUG - Exercise: \(exercise.id)")
                        NSLog("   - result.points: \(result.points ?? -999)")
                        NSLog("   - result.score: \(result.score)")
                        NSLog("   - earnedPoints: \(earnedPoints)")
                        NSLog("   - exercise.points (expected): \(exercise.points)")
                        NSLog("   - current total score: \(score) -> will become: \(score + earnedPoints)")

                        score += earnedPoints
                        correctAnswers += 1
                        completedSteps.append(currentExerciseIndex)

                        // Save progress after successful completion
                        Task {
                            await saveCurrentProgress()
                        }
                    }

                    showConfetti = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showConfetti = false
                    }
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }

                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showFeedback = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    dismissFeedback()
                }
            }
        }
    }

    private func dismissFeedback() {
        withAnimation {
            showFeedback = false
        }

        // If answer was incorrect, clear the result so user can try again
        if let result = viewModel.exerciseResult, !result.isCorrect {
            // Delay slightly to allow feedback animation to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                viewModel.exerciseResult = nil
                // Increment counter to force ExerciseView to recreate
                exerciseResetCounter += 1
            }
        }
    }

    private func previousExercise() {
        guard hasPreviousExercise else {
            return
        }
        withAnimation {
            currentExerciseIndex -= 1
            viewModel.exerciseResult = nil
            exerciseResetCounter = 0 // Reset counter for new exercise
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func skipExercise() {
        if hasNextExercise {
            nextExercise()
        } else {
            completePhase()
        }
    }

    private func nextExercise() {
        guard hasNextExercise else {
            return
        }

        // Mark current exercise as completed before moving
        if !completedSteps.contains(currentExerciseIndex) {
            completedSteps.append(currentExerciseIndex)
        }
        withAnimation {
            currentExerciseIndex += 1
            viewModel.exerciseResult = nil
            exerciseResetCounter = 0 // Reset counter for new exercise
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Save progress after navigation
        Task {
            await saveCurrentProgress()
        }
    }

    private func nextExerciseOrComplete() {
        // Prevent action if speech validation is in progress
        guard !isSpeechValidationInProgress else {
            return
        }

        if hasNextExercise {
            nextExercise()
        } else {
            completePhase()
        }
    }

    private func completePhase() {
        // Prevent completion if speech validation is in progress
        guard !isSpeechValidationInProgress else {
            return
        }

        guard let currentPhase = selectedPhase else {
            return
        }

        // Calculate score as ratio, ensuring it's between 0.0 and 1.0
        // Clamp to prevent backend validation errors if score somehow exceeds totalScore
        let rawScore = totalScore > 0 ? Double(score) / Double(totalScore) : 0.0
        let finalScore = min(max(rawScore, 0.0), 1.0)

        NSLog("📊 Phase completion score: %d / %d = %.2f (clamped to %.2f)", score, totalScore, rawScore, finalScore)

        Task {
            await viewModel.completePhase(
                roadmapId: roadmapId,
                lessonId: lessonId,
                phaseNumber: currentPhase.phaseNumber,
                score: finalScore
            )

            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showPhaseCompletion = true
            }

            showConfetti = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            // Auto-navigate to next phase after showing completion stats
            // Matches frontend behavior: automatic navigation without manual button tap
            if currentPhase.phaseNumber < 4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showConfetti = false
                    // Automatically move to next phase
                    moveToNextPhase()
                }
            } else {
                // Last phase - just stop confetti
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showConfetti = false
                }
            }
        }
    }

    private func moveToNextPhase() {
        guard let currentPhase = selectedPhase else {
            return
        }

        Task {
            withAnimation {
                showPhaseCompletion = false
            }

            let nextPhaseNumber = currentPhase.phaseNumber + 1
            guard nextPhaseNumber <= 4 else {
                dismiss()
                return
            }

            // ALWAYS reload phases to ensure we have fresh data with exercises
            await viewModel.loadLessonPhases(roadmapId: roadmapId, lessonId: lessonId)

            // CRITICAL: Reload phase progress to update lock/unlock states after phase completion
            // Without this, LessonDetailView shows stale lock states when user navigates back
            await viewModel.loadPhaseProgress(lessonId: lessonId)

            // Find next phase and update the binding to trigger navigation
            if let nextPhase = viewModel.lessonPhases.first(where: { $0.phaseNumber == nextPhaseNumber }) {
                // CRITICAL: Just update the binding - SwiftUI will automatically navigate
                // Don't call dismiss() as that would set selectedPhase = nil and cancel navigation
                selectedPhase = nextPhase
            } else {
                dismiss()
            }
        }
    }
}

// MARK: - Supporting Components

private struct StatRow: View {
    let label: String
    let value: String
    let icon: String

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            HStack(spacing: LLSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(LLColors.primary.color(for: colorScheme))

                Text(label)
                    .font(LLTypography.body())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }

            Spacer()

            Text(value)
                .font(LLTypography.h4())
                .fontWeight(.semibold)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
        }
    }
}

// MARK: - Confetti View

private struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            ForEach(confettiPieces) { piece in
                ConfettiPieceView(piece: piece)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            generateConfetti()
        }
    }

    private func generateConfetti() {
        let palette = [
            LLColors.foreground.color(for: colorScheme),
            LLColors.mutedForeground.color(for: colorScheme),
            LLColors.border.color(for: colorScheme),
            LLColors.primary.color(for: colorScheme)
        ]
        confettiPieces = (0..<50).map { _ in
            ConfettiPiece(
                x: Double.random(in: 0...UIScreen.main.bounds.width),
                y: -20,
                color: palette.randomElement() ?? LLColors.foreground.color(for: colorScheme),
                rotation: Double.random(in: 0...360)
            )
        }
    }
}

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let color: Color
    let rotation: Double
}

private struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    @State private var yOffset: Double = 0
    @State private var rotation: Double = 0

    var body: some View {
        Rectangle()
            .fill(piece.color)
            .frame(width: 10, height: 10)
            .rotationEffect(.degrees(rotation))
            .position(x: piece.x, y: piece.y + yOffset)
            .onAppear {
                withAnimation(.easeIn(duration: 2)) {
                    yOffset = UIScreen.main.bounds.height + 100
                }
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Preview
// TODO: Re-enable after fixing mock data
/*
#Preview("Lesson Phase") {
    NavigationStack {
        LessonPhaseView(
            roadmapId: "test-roadmap",
            lessonId: "test-lesson",
            phase: LessonPhaseDefinition.mockPhase1
        )
    }
}
*/
