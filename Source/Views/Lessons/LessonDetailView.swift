//
//  LessonDetailView.swift
//  LanguageLuid
//
//  Lesson overview before starting with comprehensive metadata
//  Shows learning objectives, vocabulary preview, and phase cards
//

import SwiftUI

struct LessonDetailView: View {
    // MARK: - Properties

    let roadmapId: String
    let lessonId: String

    @StateObject private var viewModel = LessonViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var showStartConfirmation = false
    @State private var selectedPhase: LessonPhaseDefinition?

    // MARK: - Body

    var body: some View {
        ZStack {
            LLColors.background.color(for: colorScheme)
                .ignoresSafeArea()

            if viewModel.isLoading {
                loadingState
            } else if let lesson = viewModel.selectedLesson {
                lessonContent(lesson: lesson)
            }

            NavigationLink(
                destination: Group {
                    if let phase = selectedPhase {
                        LessonPhaseView(
                            roadmapId: roadmapId,
                            lessonId: lessonId,
                            phase: phase
                        )
                    } else {
                        EmptyView()
                    }
                },
                isActive: Binding(
                    get: { selectedPhase != nil },
                    set: { isActive in
                        if !isActive {
                            selectedPhase = nil
                        }
                    }
                )
            ) {
                EmptyView()
            }
            .hidden()
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadLessonData()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }

    // MARK: - Lesson Content

    private func lessonContent(lesson: Lesson) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LLSpacing.lg) {
                // Header
                lessonHeader(lesson)

                // Metadata Badges
                metadataSection(lesson)

                // Description
                if let description = lesson.description {
                    descriptionSection(description)
                }

                // Learning Objectives
                if let objectives = lesson.learningObjectives, !objectives.isEmpty {
                    learningObjectivesSection(objectives)
                }

                // Vocabulary Preview
                if let vocabulary = lesson.vocabulary, !vocabulary.isEmpty {
                    vocabularyPreviewSection(vocabulary)
                }

                // Grammar Points
                if let grammarPoints = lesson.grammarPoints, !grammarPoints.isEmpty {
                    grammarPointsSection(grammarPoints)
                }

                // Key Phrases
                if let phrases = lesson.phrases, !phrases.isEmpty {
                    keyPhrasesSection(phrases)
                }

                // Prerequisites
                if lesson.hasPrerequisites, let prerequisites = lesson.prerequisites {
                    prerequisitesSection(prerequisites)
                }

                // Phase Cards
                if !viewModel.lessonPhases.isEmpty {
                    phaseCardsSection
                }

                // Action Buttons
                actionButtonsSection(lesson)
            }
            .padding(LLSpacing.md)
            .padding(.bottom, LLSpacing.xxl)
        }
    }

    // MARK: - Header

    private func lessonHeader(_ lesson: Lesson) -> some View {
        VStack(alignment: .leading, spacing: LLSpacing.sm) {
            HStack {
                Text(lesson.lessonNumberFormatted)
                    .font(LLTypography.h1())
                    .fontWeight(.bold)
                    .foregroundColor(LLColors.primary.color(for: colorScheme))

                Spacer()

                StatusBadge(status: viewModel.currentLessonStatus)
            }

            Text(lesson.title)
                .font(LLTypography.h2())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            if let subtitle = lesson.subtitle {
                Text(subtitle)
                    .font(LLTypography.body())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
        }
    }

    // MARK: - Metadata Section

    private func metadataSection(_ lesson: Lesson) -> some View {
        LLCard(style: .outlined, padding: .md) {
            HStack(spacing: LLSpacing.lg) {
                MetadataItem(
                    icon: "book.closed.fill",
                    label: "Level",
                    value: lesson.cefrLevel.rawValue.uppercased()
                )

                Divider()
                    .frame(height: 40)

                MetadataItem(
                    icon: "clock.fill",
                    label: "Duration",
                    value: lesson.estimatedDurationFormatted
                )

                Divider()
                    .frame(height: 40)

                MetadataItem(
                    icon: "star.fill",
                    label: "Points",
                    value: "\(lesson.pointsValue ?? 0)"
                )

                Divider()
                    .frame(height: 40)

                MetadataItem(
                    icon: "chart.bar.fill",
                    label: "Difficulty",
                    value: "\(lesson.difficulty)/10"
                )
            }
        }
    }

    // MARK: - Description Section

    private func descriptionSection(_ description: String) -> some View {
        SectionContainer(title: "About This Lesson", icon: "info.circle.fill") {
            Text(description)
                .font(LLTypography.body())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                .lineSpacing(4)
        }
    }

    // MARK: - Learning Objectives Section

    private func learningObjectivesSection(_ objectives: [String]) -> some View {
        SectionContainer(title: "What You'll Learn", icon: "target") {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                ForEach(Array(objectives.enumerated()), id: \.offset) { index, objective in
                    HStack(alignment: .top, spacing: LLSpacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(LLColors.success.color(for: colorScheme))
                            .font(.system(size: 16))

                        Text(objective)
                            .font(LLTypography.body())
                            .foregroundColor(LLColors.foreground.color(for: colorScheme))
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Vocabulary Preview Section

    private func vocabularyPreviewSection(_ vocabulary: [VocabularyItem]) -> some View {
        SectionContainer(title: "Vocabulary Preview", icon: "text.book.closed.fill") {
            VStack(spacing: LLSpacing.sm) {
                ForEach(vocabulary.prefix(5)) { item in
                    VocabularyPreviewCard(item: item)
                }

                if vocabulary.count > 5 {
                    Text("+ \(vocabulary.count - 5) more words")
                        .font(LLTypography.bodySmall())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        .frame(maxWidth: .infinity)
                        .padding(.top, LLSpacing.xs)
                }
            }
        }
    }

    // MARK: - Grammar Points Section

    private func grammarPointsSection(_ grammarPoints: [String]) -> some View {
        SectionContainer(title: "Grammar Focus", icon: "book.fill") {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                ForEach(Array(grammarPoints.enumerated()), id: \.offset) { index, point in
                    HStack(alignment: .top, spacing: LLSpacing.sm) {
                        Text("\(index + 1).")
                            .font(LLTypography.body())
                            .fontWeight(.semibold)
                            .foregroundColor(LLColors.primary.color(for: colorScheme))

                        Text(point)
                            .font(LLTypography.body())
                            .foregroundColor(LLColors.foreground.color(for: colorScheme))
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Key Phrases Section

    private func keyPhrasesSection(_ phrases: [PhraseItem]) -> some View {
        SectionContainer(title: "Key Phrases", icon: "bubble.left.and.bubble.right.fill") {
            VStack(spacing: LLSpacing.sm) {
                ForEach(phrases.prefix(3)) { phrase in
                    PhrasePreviewCard(phrase: phrase)
                }

                if phrases.count > 3 {
                    Text("+ \(phrases.count - 3) more phrases")
                        .font(LLTypography.bodySmall())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        .frame(maxWidth: .infinity)
                        .padding(.top, LLSpacing.xs)
                }
            }
        }
    }

    // MARK: - Prerequisites Section

    private func prerequisitesSection(_ prerequisites: [String]) -> some View {
        SectionContainer(title: "Prerequisites", icon: "exclamationmark.triangle.fill") {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                ForEach(prerequisites, id: \.self) { prereqId in
                    HStack(spacing: LLSpacing.sm) {
                        Image(systemName: "link.circle.fill")
                            .foregroundColor(LLColors.info.color(for: colorScheme))

                        Text("Complete Lesson \(prereqId)")
                            .font(LLTypography.bodySmall())
                            .foregroundColor(LLColors.foreground.color(for: colorScheme))

                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Phase Cards Section

    private var phaseCardsSection: some View {
        SectionContainer(title: "Lesson Phases", icon: "square.stack.3d.up.fill") {
            VStack(spacing: LLSpacing.md) {
                ForEach(viewModel.lessonPhases) { phase in
                    PhaseCard(
                        phase: phase,
                        progress: phaseProgress(for: phase.phaseNumber),
                        onTap: {
                            // Only allow navigation if phase is not locked
                            let progress = phaseProgress(for: phase.phaseNumber)
                            if progress?.status != .locked {
                                selectedPhase = phase
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Action Buttons Section

    private func actionButtonsSection(_ lesson: Lesson) -> some View {
        VStack(spacing: LLSpacing.md) {
            if viewModel.isCurrentLessonCompleted {
                LLButton(
                    "Review Lesson",
                    icon: Image(systemName: "arrow.clockwise"),
                    style: .outline,
                    size: .lg,
                    fullWidth: true
                ) {
                    startLesson()
                }
            }

            if viewModel.isCurrentLessonInProgress {
                LLButton(
                    "Continue Learning",
                    icon: Image(systemName: "play.fill"),
                    style: .primary,
                    size: .lg,
                    isLoading: viewModel.isLoading,
                    fullWidth: true
                ) {
                    continueLesson()
                }
            } else if viewModel.canStartCurrentLesson {
                LLButton(
                    "Start Lesson",
                    icon: Image(systemName: "play.fill"),
                    style: .primary,
                    size: .lg,
                    isLoading: viewModel.isLoading,
                    fullWidth: true
                ) {
                    showStartConfirmation = true
                }
            }

            if viewModel.isCurrentLessonLocked {
                VStack(spacing: LLSpacing.sm) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 32))
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                    Text("Complete prerequisites to unlock")
                        .font(LLTypography.body())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
                .frame(maxWidth: .infinity)
                .padding(LLSpacing.lg)
            }
        }
        .alert("Start Lesson", isPresented: $showStartConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Start") {
                startLesson()
            }
        } message: {
            Text("Ready to begin? This lesson will take approximately \(viewModel.selectedLesson?.estimatedDurationFormatted ?? "45 minutes").")
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: LLSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(LLColors.primary.color(for: colorScheme))

            Text("Loading lesson...")
                .font(LLTypography.body())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helper Functions

    private func loadLessonData() async {
        await viewModel.loadLesson(
            roadmapId: roadmapId,
            lessonId: lessonId,
            includePhases: true,
            includeExercises: false
        )

        // Explicitly load phases if they weren't included in the lesson response
        if viewModel.lessonPhases.isEmpty {
            await viewModel.loadLessonPhases(roadmapId: roadmapId, lessonId: lessonId)
        }

        await viewModel.loadUserProgress(roadmapId: roadmapId, lessonId: lessonId)
        await viewModel.loadPhaseProgress(lessonId: lessonId)
    }

    private func phaseProgress(for phaseNumber: Int) -> PhaseState? {
        viewModel.phaseProgressSummary?.phaseStates.first { $0.phase == phaseNumber }
    }

    private func startLesson() {
        Task {
            await viewModel.startLesson(roadmapId: roadmapId, lessonId: lessonId)

            // Ensure phases are loaded
            if viewModel.lessonPhases.isEmpty {
                await viewModel.loadLessonPhases(roadmapId: roadmapId, lessonId: lessonId)
            }

            // Navigate to first phase (or current phase if set by startLesson)
            if let currentPhase = viewModel.currentPhase {
                selectedPhase = currentPhase
            } else if let firstPhase = viewModel.lessonPhases.first {
                selectedPhase = firstPhase
            }
        }
    }

    private func continueLesson() {
        // Navigate to current phase
        NSLog("🔵 continueLesson() called")
        NSLog("🔵 viewModel.currentPhase: \(viewModel.currentPhase?.phaseNumber ?? -1)")
        NSLog("🔵 viewModel.phaseProgressSummary?.currentPhase: \(viewModel.phaseProgressSummary?.currentPhase ?? -1)")
        NSLog("🔵 viewModel.lessonPhases count: \(viewModel.lessonPhases.count)")

        if let currentPhase = viewModel.currentPhase {
            NSLog("🔵 Setting selectedPhase to phase \(currentPhase.phaseNumber)")
            selectedPhase = currentPhase
        } else {
            NSLog("❌ viewModel.currentPhase is nil, falling back to first phase")
            // Fallback: if currentPhase is nil, use first phase
            if let firstPhase = viewModel.lessonPhases.first {
                selectedPhase = firstPhase
            }
        }
    }
}

// MARK: - Supporting Components

private struct StatusBadge: View {
    let status: LessonStatus

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: LLSpacing.xs) {
            Image(systemName: status.icon)
                .font(.system(size: 14))

            Text(status.displayName)
                .font(LLTypography.caption())
                .fontWeight(.semibold)
        }
        .foregroundColor(badgeColor)
        .padding(.horizontal, LLSpacing.sm)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(badgeColor.opacity(0.15))
        )
    }

    private var badgeColor: Color {
        switch status {
        case .completed:
            return LLColors.success.color(for: colorScheme)
        case .inProgress:
            return LLColors.warning.color(for: colorScheme)
        case .available, .notStarted:
            return LLColors.primary.color(for: colorScheme)
        case .locked:
            return LLColors.mutedForeground.color(for: colorScheme)
        }
    }
}

private struct MetadataItem: View {
    let icon: String
    let label: String
    let value: String

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: LLSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(LLColors.primary.color(for: colorScheme))

            Text(value)
                .font(LLTypography.h4())
                .fontWeight(.bold)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            Text(label)
                .font(LLTypography.captionSmall())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SectionContainer<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    @Environment(\.colorScheme) var colorScheme

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LLSpacing.md) {
            HStack(spacing: LLSpacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(LLColors.primary.color(for: colorScheme))

                Text(title)
                    .font(LLTypography.h3())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
            }

            LLCard(style: .outlined, padding: .md) {
                content
            }
        }
    }
}

private struct VocabularyPreviewCard: View {
    let item: VocabularyItem

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: LLSpacing.md) {
            VStack(alignment: .leading, spacing: LLSpacing.xs) {
                Text(item.displayWord)
                    .font(LLTypography.body())
                    .fontWeight(.semibold)
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))

                if let pronunciation = item.pronunciation {
                    Text(pronunciation)
                        .font(LLTypography.captionSmall())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
            }

            Spacer()

            Text(item.translation)
                .font(LLTypography.body())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
        .padding(LLSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                .fill(LLColors.muted.color(for: colorScheme).opacity(0.3))
        )
    }
}

private struct PhrasePreviewCard: View {
    let phrase: PhraseItem

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: LLSpacing.xs) {
            Text(phrase.phrase)
                .font(LLTypography.body())
                .fontWeight(.semibold)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            Text(phrase.translation)
                .font(LLTypography.bodySmall())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

            if let context = phrase.usageContext {
                HStack(spacing: LLSpacing.xs) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 10))

                    Text(context)
                        .font(LLTypography.captionSmall())
                }
                .foregroundColor(LLColors.info.color(for: colorScheme))
            }
        }
        .padding(LLSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                .fill(LLColors.muted.color(for: colorScheme).opacity(0.3))
        )
    }
}

private struct PhaseCard: View {
    let phase: LessonPhaseDefinition
    let progress: PhaseState?
    let onTap: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        LLCard(style: .elevated, padding: .md) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                HStack {
                    HStack(spacing: LLSpacing.sm) {
                        Image(systemName: phase.icon)
                            .font(.system(size: 20))
                            .foregroundColor(LLColors.primary.color(for: colorScheme))

                        Text("Phase \(phase.phaseNumber)")
                            .font(LLTypography.h4())
                            .fontWeight(.bold)
                            .foregroundColor(LLColors.foreground.color(for: colorScheme))
                    }

                    Spacer()

                    if let progress = progress {
                        PhaseStatusBadge(status: progress.status)
                    }
                }

                Text(phase.phaseName)
                    .font(LLTypography.body())
                    .fontWeight(.semibold)
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))

                if let description = phase.description {
                    Text(description)
                        .font(LLTypography.bodySmall())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        .lineLimit(2)
                }

                HStack(spacing: LLSpacing.lg) {
                    PhaseMetaItem(icon: "clock", text: phase.estimatedDurationFormatted)

                    PhaseMetaItem(icon: "list.bullet", text: "\(phase.exerciseCount) exercises")

                    Spacer()
                }

                // Progress indicator
                if let progress = progress, let score = progress.score {
                    VStack(spacing: LLSpacing.xs) {
                        HStack {
                            Text("Score")
                                .font(LLTypography.captionSmall())
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                            Spacer()

                            Text("\(progress.scorePercentage)%")
                                .font(LLTypography.captionSmall())
                                .fontWeight(.semibold)
                                .foregroundColor(scoreColor(progress.scorePercentage))
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: LLSpacing.radiusFull)
                                    .fill(LLColors.muted.color(for: colorScheme))
                                    .frame(height: 4)

                                RoundedRectangle(cornerRadius: LLSpacing.radiusFull)
                                    .fill(scoreColor(progress.scorePercentage))
                                    .frame(width: geometry.size.width * score, height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                }
            }
        }
        .opacity(progress?.status == .locked ? 0.6 : 1.0)
        .onTapGesture {
            onTap()
        }
    }

    private func scoreColor(_ percentage: Int) -> Color {
        switch percentage {
        case 90...100:
            return LLColors.success.color(for: colorScheme)
        case 70..<90:
            return LLColors.primary.color(for: colorScheme)
        default:
            return LLColors.warning.color(for: colorScheme)
        }
    }
}

private struct PhaseStatusBadge: View {
    let status: PhaseStatus

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Image(systemName: status.icon)
            .font(.system(size: 16))
            .foregroundColor(badgeColor)
    }

    private var badgeColor: Color {
        switch status {
        case .completed:
            return LLColors.success.color(for: colorScheme)
        case .inProgress, .current:
            return LLColors.warning.color(for: colorScheme)
        case .available:
            return LLColors.primary.color(for: colorScheme)
        case .locked:
            return LLColors.mutedForeground.color(for: colorScheme)
        }
    }
}

private struct PhaseMetaItem: View {
    let icon: String
    let text: String

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: LLSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(LLTypography.captionSmall())
        }
        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
    }
}

// MARK: - Preview

#Preview("Lesson Detail") {
    NavigationStack {
        LessonDetailView(
            roadmapId: "test-roadmap",
            lessonId: "test-lesson"
        )
    }
}
