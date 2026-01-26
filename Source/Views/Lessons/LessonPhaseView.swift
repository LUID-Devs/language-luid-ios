//
//  LessonPhaseView.swift
//  LanguageLuid
//
//  Active lesson player for one phase with exercise navigation
//  Shows progress, timer, score, and phase completion
//

import SwiftUI

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
    @Environment(\.tabBarVisible) private var tabBarVisible

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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showExitConfirmation = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Exit")
                            .font(LLTypography.bodySmall())
                    }
                    .foregroundColor(LLColors.destructive.color(for: colorScheme))
                }
            }
        }
        .onAppear {
            // Hide tab bar when entering lesson phase
            tabBarVisible.wrappedValue = false
        }
        .onDisappear {
            // Show tab bar when leaving lesson phase
            tabBarVisible.wrappedValue = true

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
                    NSLog("⚠️ [onDisappear] Skipping save - no viewModel or not loaded")
                    return
                }

                // Check exercises count on main actor
                let hasExercises = await MainActor.run { !viewModel.exercises.isEmpty }
                guard hasExercises else {
                    NSLog("⚠️ [onDisappear] Skipping save - no exercises")
                    return
                }

                NSLog("💾 [onDisappear] Saving progress (detached task)...")
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
                NSLog("⚠️ [PhaseView] Task triggered but selectedPhase is nil")
                return
            }
            NSLog("🎬 [PhaseView] Task triggered for phase \(currentPhase.phaseNumber) (id: \(currentPhase.id))")
            NSLog("🎬 [PhaseView] Phase name: \(currentPhase.phaseName)")

            // Reset all state variables
            NSLog("🔄 [PhaseView] Resetting all state variables...")
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
            NSLog("📥 [PhaseView] Loading exercises for phase \(currentPhase.phaseNumber)...")
            await loadExercises(for: currentPhase)
            NSLog("📥 [PhaseView] Loaded \(viewModel.exercises.count) exercises")
            if let first = viewModel.exercises.first {
                NSLog("   📝 First exercise prompt: \(first.prompt)")
            }

            await loadAndRestoreProgress(for: currentPhase)
            NSLog("✅ [PhaseView] Phase \(currentPhase.phaseNumber) ready with \(viewModel.exercises.count) exercises")
        }
        .onReceive(timer) { _ in
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
                        NSLog("⚠️ [Exit] Skipping save - no valid data")
                        dismiss()
                        return
                    }

                    NSLog("💾 [Exit] Saving progress before dismiss...")
                    await viewModel.saveStepProgress(
                        roadmapId: roadmap,
                        lessonId: lesson,
                        phaseNumber: phaseNum,
                        currentStep: currentStep,
                        completedSteps: completed
                    )
                    NSLog("✅ [Exit] Progress saved, dismissing...")
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

                    if exercise.hasHints {
                        Button(action: showHint) {
                            HStack(spacing: LLSpacing.xs) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 12))
                                Text("Hint")
                                    .font(LLTypography.captionSmall())
                            }
                            .foregroundColor(LLColors.warning.color(for: colorScheme))
                            .padding(.horizontal, LLSpacing.sm)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(LLColors.warning.color(for: colorScheme).opacity(0.15))
                            )
                        }
                    }
                }
                .padding(.horizontal, LLSpacing.md)
                .padding(.top, LLSpacing.md)

                // Exercise View
                ExerciseView(
                    exercise: exercise,
                    languageCode: languageLocale,
                    onSubmit: { response in
                        submitExercise(response)
                    },
                    onSpeechValidationStarted: {
                        NSLog("🔊 [PhaseView] Speech validation started, blocking phase completion")
                        isSpeechValidationInProgress = true
                    }
                )
                .id(exercise.id) // Force view recreation when exercise changes
                .padding(.horizontal, LLSpacing.md)
            }
            .padding(.bottom, 100) // Space for bottom navigation
        }
    }

    // MARK: - Bottom Navigation

    private var bottomNavigation: some View {
        let hasResult = viewModel.exerciseResult != nil
        let _ = NSLog("🎯 [BottomNav] Rendering - exerciseResult is \(hasResult ? "SET" : "NIL"), currentIndex=\(currentExerciseIndex), total=\(viewModel.exercises.count), hasNext=\(hasNextExercise)")

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

                // Check/Next Button
                if hasResult {
                    let buttonLabel = hasNextExercise ? "Next" : "Complete"
                    let _ = NSLog("🎯 [BottomNav] Rendering '\(buttonLabel)' button (hasNext=\(hasNextExercise))")
                    LLButton(
                        buttonLabel,
                        icon: Image(systemName: hasNextExercise ? "chevron.right" : "checkmark"),
                        style: .primary,
                        size: .md
                    ) {
                        NSLog("🔘 \(buttonLabel) button tapped, hasNext=\(hasNextExercise)")
                        nextExerciseOrComplete()
                    }
                } else {
                    let _ = NSLog("🎯 [BottomNav] No result yet - waiting for answer")
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
        let progress = Double(currentExerciseIndex + 1) / Double(viewModel.exercises.count)
        NSLog("📊 [Progress] currentIndex=\(currentExerciseIndex), total=\(viewModel.exercises.count), progress=\(progress * 100)%")
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

    // Convert target language to locale code (e.g., "es" -> "es-ES", "fr" -> "fr-FR")
    private var languageLocale: String {
        guard let targetLanguage = authViewModel.currentUser?.targetLanguage else {
            return "es-ES" // Default fallback
        }

        // Map language codes to primary locales
        let localeMap: [String: String] = [
            "es": "es-ES",
            "fr": "fr-FR",
            "de": "de-DE",
            "it": "it-IT",
            "pt": "pt-PT",
            "ja": "ja-JP",
            "ko": "ko-KR",
            "zh": "zh-CN",
            "ar": "ar-SA",
            "ru": "ru-RU",
            "hi": "hi-IN",
            "nl": "nl-NL",
            "sv": "sv-SE",
            "pl": "pl-PL",
            "tr": "tr-TR"
        ]

        return localeMap[targetLanguage.lowercased()] ?? "\(targetLanguage)-\(targetLanguage.uppercased())"
    }

    // MARK: - Actions

    private func loadExercises(for currentPhase: LessonPhaseDefinition) async {
        NSLog("📚 [PhaseView] Loading exercises for phase \(currentPhase.phaseNumber)...")
        await viewModel.loadExercises(
            roadmapId: roadmapId,
            lessonId: lessonId,
            phaseNumber: currentPhase.phaseNumber
        )

        if !viewModel.exercises.isEmpty {
            exercisesLoadedSuccessfully = true
            NSLog("✅ [PhaseView] Exercises loaded successfully - Count: \(viewModel.exercises.count)")
        } else {
            NSLog("⚠️ [PhaseView] No exercises loaded!")
        }

        totalScore = viewModel.exercises.reduce(0) { $0 + $1.points }
    }

    private func loadAndRestoreProgress(for currentPhase: LessonPhaseDefinition) async {
        NSLog("📊 [PhaseView] Loading step progress for phase \(currentPhase.phaseNumber)...")

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

            NSLog("📊 [PhaseView] Restoring progress - Step: \(restoredStep), Completed: \(restoredCompleted)")

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

            NSLog("✅ [PhaseView] Progress restored - Step: \(validStep), Score: \(restoredScore)/\(totalScore), Correct: \(restoredCorrectAnswers)")
        } else {
            NSLog("ℹ️ [PhaseView] No saved progress - starting from beginning")
            DispatchQueue.main.async {
                self.isLoadingProgress = false
            }
        }
    }

    private func saveCurrentProgress() async {
        // Don't save if exercises never loaded successfully
        guard exercisesLoadedSuccessfully else {
            NSLog("⚠️ [PhaseView] Skipping save - exercises never loaded successfully")
            return
        }

        // Don't save if no exercises in viewModel
        guard !viewModel.exercises.isEmpty else {
            NSLog("⚠️ [PhaseView] Skipping save - exercises array is empty")
            return
        }

        guard let currentPhase = selectedPhase else {
            NSLog("⚠️ [PhaseView] Skipping save - selectedPhase is nil")
            return
        }

        // Check if task is cancelled before saving
        guard !Task.isCancelled else {
            NSLog("⚠️ [PhaseView] Task cancelled - using detached task to save anyway")
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

        NSLog("💾 [PhaseView] Saving progress - Step: \(currentExerciseIndex), Completed: \(completedSteps)")

        await viewModel.saveStepProgress(
            roadmapId: roadmapId,
            lessonId: lessonId,
            phaseNumber: currentPhase.phaseNumber,
            currentStep: currentExerciseIndex,
            completedSteps: completedSteps
        )
    }

    private func submitExercise(_ response: ResponseValue) {
        NSLog("🎯 [PhaseView] submitExercise called")
        Task {
            // Ensure flag is always cleared, even if an error occurs
            defer {
                isSpeechValidationInProgress = false
                NSLog("🔊 [PhaseView] Speech validation completed, unblocking phase completion")
            }

            guard let exercise = currentExercise else {
                NSLog("❌ [PhaseView] No current exercise!")
                return
            }

            NSLog("🎯 [PhaseView] Calling viewModel.submitExercise...")
            await viewModel.submitExercise(
                roadmapId: roadmapId,
                lessonId: lessonId,
                exerciseId: exercise.id,
                responseValue: response
            )

            NSLog("🎯 [PhaseView] After await, checking viewModel.exerciseResult...")
            NSLog("🎯 [PhaseView] viewModel.exerciseResult is \(viewModel.exerciseResult != nil ? "SET" : "NIL")")

            if let result = viewModel.exerciseResult {
                NSLog("✅ [PhaseView] Exercise result received: correct=\(result.isCorrect), score=\(result.score)")
                isAnswerCorrect = result.isCorrect
                // Use feedback.message if available, otherwise use explanation, otherwise use a default message
                feedbackMessage = result.feedback?.message ?? result.explanation ?? (result.isCorrect ? "Correct!" : "Incorrect")
                let earnedPoints = result.points ?? Int(result.score)
                score += earnedPoints

                if result.isCorrect {
                    correctAnswers += 1
                    showConfetti = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)

                    // Mark exercise as completed when answered correctly
                    if !completedSteps.contains(currentExerciseIndex) {
                        completedSteps.append(currentExerciseIndex)
                        // Save progress after successful completion
                        Task {
                            await saveCurrentProgress()
                        }
                    }

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
            } else {
                NSLog("❌ [PhaseView] No exercise result after submission!")
            }
        }
    }

    private func dismissFeedback() {
        withAnimation {
            showFeedback = false
        }
    }

    private func previousExercise() {
        guard hasPreviousExercise else {
            NSLog("❌ [PhaseView] previousExercise blocked - no previous exercise")
            return
        }
        NSLog("⬅️ [PhaseView] Moving to previous exercise (\(currentExerciseIndex - 1)/\(viewModel.exercises.count))")
        withAnimation {
            currentExerciseIndex -= 1
            viewModel.exerciseResult = nil
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func skipExercise() {
        NSLog("⏭️ [PhaseView] skipExercise - hasNext=\(hasNextExercise)")
        if hasNextExercise {
            nextExercise()
        } else {
            completePhase()
        }
    }

    private func nextExercise() {
        guard hasNextExercise else {
            NSLog("❌ [PhaseView] nextExercise blocked - no next exercise")
            return
        }

        // Mark current exercise as completed before moving
        if !completedSteps.contains(currentExerciseIndex) {
            completedSteps.append(currentExerciseIndex)
        }

        NSLog("➡️ [PhaseView] Moving to next exercise (\(currentExerciseIndex + 1)/\(viewModel.exercises.count))")
        withAnimation {
            currentExerciseIndex += 1
            viewModel.exerciseResult = nil
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
            NSLog("⚠️ [PhaseView] Blocked nextExerciseOrComplete - speech validation in progress")
            return
        }

        NSLog("🎯 [PhaseView] nextExerciseOrComplete - currentIndex=\(currentExerciseIndex), total=\(viewModel.exercises.count), hasNext=\(hasNextExercise)")

        if hasNextExercise {
            NSLog("➡️ [PhaseView] Has next exercise, calling nextExercise()")
            nextExercise()
        } else {
            NSLog("✅ [PhaseView] Last exercise, calling completePhase()")
            completePhase()
        }
    }

    private func completePhase() {
        // Prevent completion if speech validation is in progress
        guard !isSpeechValidationInProgress else {
            NSLog("⚠️ [PhaseView] Blocked completePhase - speech validation in progress")
            return
        }

        guard let currentPhase = selectedPhase else {
            NSLog("❌ [PhaseView] Cannot complete phase - selectedPhase is nil")
            return
        }

        let finalScore = Double(score) / Double(totalScore)

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
                NSLog("✅ [PhaseView] Phase \(currentPhase.phaseNumber) completed! Auto-navigating to Phase \(currentPhase.phaseNumber + 1) in 3 seconds...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showConfetti = false
                    // Automatically move to next phase
                    moveToNextPhase()
                }
            } else {
                // Last phase - just stop confetti
                NSLog("✅ [PhaseView] Final phase completed! Lesson finished.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showConfetti = false
                }
            }
        }
    }

    private func moveToNextPhase() {
        guard let currentPhase = selectedPhase else {
            NSLog("❌ [PhaseView] Cannot move to next phase - selectedPhase is nil")
            return
        }

        Task {
            withAnimation {
                showPhaseCompletion = false
            }

            let nextPhaseNumber = currentPhase.phaseNumber + 1
            guard nextPhaseNumber <= 4 else {
                NSLog("ℹ️ [PhaseView] No more phases, dismissing to lesson overview")
                dismiss()
                return
            }

            NSLog("🔍 [PhaseView] Current phases count: \(viewModel.lessonPhases.count)")
            NSLog("🔍 [PhaseView] Looking for phase \(nextPhaseNumber)")

            // ALWAYS reload phases to ensure we have fresh data with exercises
            NSLog("📥 [PhaseView] Reloading phases from backend...")
            await viewModel.loadLessonPhases(roadmapId: roadmapId, lessonId: lessonId)
            NSLog("📥 [PhaseView] Phases reloaded. Count: \(viewModel.lessonPhases.count)")

            // Log all available phases
            for p in viewModel.lessonPhases {
                NSLog("📝 [PhaseView] Available phase: \(p.phaseNumber) - \(p.phaseName)")
            }

            // Find next phase and update the binding to trigger navigation
            if let nextPhase = viewModel.lessonPhases.first(where: { $0.phaseNumber == nextPhaseNumber }) {
                NSLog("✅ [PhaseView] Found phase \(nextPhaseNumber): \(nextPhase.phaseName)")
                NSLog("✅ [PhaseView] Phase has \(nextPhase.exercises?.count ?? 0) exercises")

                // CRITICAL: Just update the binding - SwiftUI will automatically navigate
                // Don't call dismiss() as that would set selectedPhase = nil and cancel navigation
                selectedPhase = nextPhase
                NSLog("✅ [PhaseView] selectedPhase updated to phase \(nextPhaseNumber)")
            } else {
                NSLog("❌ [PhaseView] Could not find phase \(nextPhaseNumber) among \(viewModel.lessonPhases.count) phases")
                NSLog("❌ [PhaseView] Available phase numbers: \(viewModel.lessonPhases.map { $0.phaseNumber })")
                dismiss()
            }
        }
    }

    private func showHint() {
        // Show hint alert or toast
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
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
