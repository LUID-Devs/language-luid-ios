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

    @StateObject private var viewModel = LessonViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var currentExerciseIndex = 0
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
                } else if let exercise = currentExercise {
                    exerciseContainer(exercise)
                } else {
                    emptyState
                }

                // Bottom Navigation
                bottomNavigation
            }

            // Feedback Overlay
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
        .task {
            await loadExercises()
        }
        .onReceive(timer) { _ in
            elapsedSeconds += 1
        }
        .confirmationDialog("Exit Phase", isPresented: $showExitConfirmation, titleVisibility: .visible) {
            Button("Keep Learning", role: .cancel) {}
            Button("Exit", role: .destructive) {
                dismiss()
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
                    }
                )
                .padding(.horizontal, LLSpacing.md)
            }
            .padding(.bottom, 100) // Space for bottom navigation
        }
    }

    // MARK: - Bottom Navigation

    private var bottomNavigation: some View {
        HStack(spacing: LLSpacing.md) {
            // Previous Button
            LLButton(
                "Previous",
                icon: Image(systemName: "chevron.left"),
                style: .outline,
                size: .md,
                isDisabled: !viewModel.hasPreviousExercise
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
            if viewModel.exerciseResult != nil {
                LLButton(
                    viewModel.hasNextExercise ? "Next" : "Complete",
                    icon: Image(systemName: viewModel.hasNextExercise ? "chevron.right" : "checkmark"),
                    style: .primary,
                    size: .md
                ) {
                    nextExerciseOrComplete()
                }
            }
        }
        .padding(LLSpacing.md)
        .background(
            LLColors.card.color(for: colorScheme)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
        )
    }

    // MARK: - Feedback Overlay

    private var feedbackOverlay: some View {
        VStack {
            Spacer()

            LLCard(style: .elevated, padding: .lg) {
                VStack(spacing: LLSpacing.md) {
                    // Icon
                    Image(systemName: isAnswerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(isAnswerCorrect ? LLColors.success.color(for: colorScheme) : LLColors.destructive.color(for: colorScheme))
                        .scaleEffect(showFeedback ? 1 : 0.5)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showFeedback)

                    // Message
                    Text(feedbackMessage)
                        .font(LLTypography.h4())
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))
                        .multilineTextAlignment(.center)

                    // Explanation
                    if let explanation = viewModel.exerciseResult?.feedback.explanation {
                        Text(explanation)
                            .font(LLTypography.bodySmall())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                            .multilineTextAlignment(.center)
                    }

                    // Points Earned
                    if let result = viewModel.exerciseResult {
                        HStack(spacing: LLSpacing.xs) {
                            Image(systemName: "star.fill")
                                .foregroundColor(LLColors.warning.color(for: colorScheme))
                            Text("+\(Int(result.score)) XP")
                                .font(LLTypography.body())
                                .fontWeight(.semibold)
                                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                        }
                    }
                }
            }
            .padding(LLSpacing.lg)
            .transition(.move(edge: .bottom).combined(with: .opacity))

            Spacer()
                .frame(height: 150)
        }
        .background(
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissFeedback()
                }
        )
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

                    Divider()

                    // Stats
                    VStack(spacing: LLSpacing.md) {
                        StatRow(label: "Score", value: "\(score) XP", icon: "star.fill")
                        StatRow(label: "Accuracy", value: accuracyFormatted, icon: "target")
                        StatRow(label: "Time", value: timeFormatted, icon: "clock.fill")
                        StatRow(label: "XP Earned", value: "+\(score)", icon: "sparkles")
                    }

                    Divider()

                    // Buttons
                    VStack(spacing: LLSpacing.sm) {
                        if phase.phaseNumber < 4 {
                            LLButton(
                                "Next Phase",
                                icon: Image(systemName: "arrow.right"),
                                style: .primary,
                                size: .lg,
                                fullWidth: true
                            ) {
                                moveToNextPhase()
                            }
                        }

                        LLButton(
                            "Back to Lesson",
                            style: .outline,
                            size: .lg,
                            fullWidth: true
                        ) {
                            dismiss()
                        }
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

    private var exerciseProgress: Double {
        guard !viewModel.exercises.isEmpty else { return 0 }
        return Double(currentExerciseIndex + 1) / Double(viewModel.exercises.count)
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

    private func loadExercises() async {
        await viewModel.loadExercises(
            roadmapId: roadmapId,
            lessonId: lessonId,
            phaseNumber: phase.phaseNumber
        )
        totalScore = viewModel.exercises.reduce(0) { $0 + $1.points }
    }

    private func submitExercise(_ response: ResponseValue) {
        Task {
            guard let exercise = currentExercise else { return }

            await viewModel.submitExercise(
                roadmapId: roadmapId,
                lessonId: lessonId,
                exerciseId: exercise.id,
                responseValue: response
            )

            if let result = viewModel.exerciseResult {
                isAnswerCorrect = result.isCorrect
                feedbackMessage = result.feedback.message
                score += Int(result.score)

                if result.isCorrect {
                    correctAnswers += 1
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
    }

    private func previousExercise() {
        guard viewModel.hasPreviousExercise else { return }
        withAnimation {
            currentExerciseIndex -= 1
            viewModel.exerciseResult = nil
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func skipExercise() {
        if viewModel.hasNextExercise {
            nextExercise()
        } else {
            completePhase()
        }
    }

    private func nextExercise() {
        guard viewModel.hasNextExercise else { return }
        withAnimation {
            currentExerciseIndex += 1
            viewModel.exerciseResult = nil
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func nextExerciseOrComplete() {
        if viewModel.hasNextExercise {
            nextExercise()
        } else {
            completePhase()
        }
    }

    private func completePhase() {
        let finalScore = Double(score) / Double(totalScore)

        Task {
            await viewModel.completePhase(
                roadmapId: roadmapId,
                lessonId: lessonId,
                phaseNumber: phase.phaseNumber,
                score: finalScore
            )

            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showPhaseCompletion = true
            }

            showConfetti = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showConfetti = false
            }
        }
    }

    private func moveToNextPhase() {
        // Navigate to next phase (implementation depends on navigation setup)
        dismiss()
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
