//
//  LessonListView.swift
//  LanguageLuid
//
//  Lesson browser for a CEFR level with filtering and progress tracking
//  Displays lesson cards with comprehensive metadata and status indicators
//

import SwiftUI

struct LessonListView: View {
    // MARK: - Properties

    let roadmapId: String
    let cefrLevel: CEFRLevel
    let languageName: String

    @StateObject private var viewModel = LessonViewModel()
    @StateObject private var revenueCatManager = RevenueCatManager.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var selectedFilter: LessonCategory? = nil
    @State private var showGridView = false
    @State private var showPaywall = false

    // MARK: - Body

    var body: some View {
        ZStack {
            LLColors.background.color(for: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Filter Chips
                filterChipsSection

                // Lesson List/Grid
                if viewModel.isLoading {
                    loadingState
                } else if viewModel.filteredLessons.isEmpty {
                    emptyState
                } else {
                    lessonContent
                }
            }
        }
        .navigationTitle("\(cefrLevel.rawValue.uppercased()) Lessons")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showGridView.toggle() }) {
                    Image(systemName: showGridView ? "list.bullet" : "square.grid.2x2")
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))
                }
            }
        }
        .id("\(roadmapId)-\(cefrLevel.rawValue)")
        .task {
            await viewModel.loadLessons(
                roadmapId: roadmapId,
                cefrLevel: cefrLevel
            )
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView {
                // Reload lessons when premium is granted
                Task {
                    await viewModel.loadLessons(
                        roadmapId: roadmapId,
                        cefrLevel: cefrLevel
                    )
                }
            }
        }
    }

    // MARK: - Filter Chips Section

    private var filterChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LLSpacing.sm) {
                FilterChip(
                    title: "All",
                    isSelected: selectedFilter == nil,
                    count: viewModel.lessons.count
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedFilter = nil
                        viewModel.selectedCategory = nil
                    }
                }

                ForEach(LessonCategory.allCases, id: \.self) { category in
                    let count = viewModel.lessons.filter { $0.category == category }.count
                    if count > 0 {
                        FilterChip(
                            title: category.displayName,
                            isSelected: selectedFilter == category,
                            count: count
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if selectedFilter == category {
                                    selectedFilter = nil
                                    viewModel.selectedCategory = nil
                                } else {
                                    selectedFilter = category
                                    viewModel.selectedCategory = category
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, LLSpacing.md)
            .padding(.vertical, LLSpacing.sm)
        }
        .background(LLColors.card.color(for: colorScheme))
    }

    // MARK: - Lesson Content

    private var lessonContent: some View {
        ScrollView {
            if showGridView {
                gridView
            } else {
                listView
            }
        }
        .padding(.bottom, LLSpacing.xxl)
    }

    private var listView: some View {
        LazyVStack(spacing: LLSpacing.md) {
            ForEach(Array(viewModel.filteredLessons.enumerated()), id: \.element.id) { index, lesson in
                LessonCard(lesson: lesson, showPaywall: $showPaywall)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.05), value: viewModel.filteredLessons.count)
            }
        }
        .padding(LLSpacing.md)
    }

    private var gridView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: LLSpacing.md),
            GridItem(.flexible(), spacing: LLSpacing.md)
        ], spacing: LLSpacing.md) {
            ForEach(Array(viewModel.filteredLessons.enumerated()), id: \.element.id) { index, lesson in
                LessonGridCard(lesson: lesson, showPaywall: $showPaywall)
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.05), value: viewModel.filteredLessons.count)
            }
        }
        .padding(LLSpacing.md)
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: LLSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(LLColors.primary.color(for: colorScheme))

            Text("Loading lessons...")
                .font(LLTypography.body())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: LLSpacing.lg) {
            Image(systemName: "book.closed")
                .font(.system(size: 64))
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

            Text("No Lessons Found")
                .font(LLTypography.h3())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            Text(selectedFilter == nil ? "No lessons available for this level yet." : "No lessons match the selected filter.")
                .font(LLTypography.body())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, LLSpacing.xl)

            if selectedFilter != nil {
                LLButton("Clear Filter", style: .outline) {
                    withAnimation {
                        selectedFilter = nil
                        viewModel.selectedCategory = nil
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: LLSpacing.xs) {
                Text(title)
                    .font(LLTypography.caption())
                    .fontWeight(.semibold)

                Text("\(count)")
                    .font(LLTypography.captionSmall())
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isSelected ? LLColors.primaryForeground.color(for: colorScheme).opacity(0.3) : LLColors.muted.color(for: colorScheme))
                    )
            }
            .foregroundColor(isSelected ? LLColors.primaryForeground.color(for: colorScheme) : LLColors.foreground.color(for: colorScheme))
            .padding(.horizontal, LLSpacing.md)
            .padding(.vertical, LLSpacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? LLColors.primary.color(for: colorScheme) : LLColors.muted.color(for: colorScheme))
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PressableButtonStyle(isPressed: $isPressed))
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

// MARK: - Lesson Card

@MainActor
private struct LessonCard: View {
    let lesson: Lesson
    @Binding var showPaywall: Bool

    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false

    var body: some View {
        Group {
            if lesson.isLockedByPaywall {
                // Show paywall button for locked lessons
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showPaywall = true
                }) {
                    cardContent
                }
            } else {
                // Normal navigation for accessible lessons
                NavigationLink(destination: LessonDetailView(
                    roadmapId: lesson.roadmapId,
                    lessonId: lesson.id
                )) {
                    cardContent
                }
            }
        }
        .buttonStyle(ScalableButtonStyle(isPressed: $isPressed, scale: 0.98))
        .opacity(lesson.isLockedByPaywall ? 0.8 : 1.0)
    }

    private var cardContent: some View {
            LLCard(style: .elevated, padding: .none) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header Section
                    HStack(alignment: .top, spacing: LLSpacing.md) {
                        // Lesson Number Badge
                        LessonNumberBadge(number: lesson.lessonNumber, status: lesson.status)

                        // Title and Subtitle
                        VStack(alignment: .leading, spacing: LLSpacing.xs) {
                            Text(lesson.title)
                                .font(LLTypography.h4())
                                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                                .lineLimit(2)

                            if let subtitle = lesson.subtitle {
                                Text(subtitle)
                                    .font(LLTypography.bodySmall())
                                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                    .lineLimit(2)
                            }
                        }

                        Spacer()

                        // Status Icon or Lock Icon
                        if lesson.isLockedByPaywall {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 20))
                                .foregroundColor(LLColors.warning.color(for: colorScheme))
                        } else {
                            StatusIcon(status: lesson.status)
                        }
                    }
                    .padding(LLSpacing.md)

                    Divider()
                        .background(LLColors.border.color(for: colorScheme))

                    // Metadata Section
                    VStack(spacing: LLSpacing.sm) {
                        // Badges Row
                        HStack(spacing: LLSpacing.xs) {
                            if lesson.requiresPremium {
                                LLBadge("Premium", variant: .warning, size: .sm)
                            }

                            LLBadge(lesson.category.displayName, variant: .info, size: .sm)

                            if let type = lesson.lessonType {
                                LLBadge(type.displayName, variant: .secondary, size: .sm)
                            }

                            DifficultyBadge(difficulty: lesson.difficulty)

                            Spacer()
                        }

                        // Stats Row
                        HStack(spacing: LLSpacing.lg) {
                            LessonStatItem(icon: "clock", text: lesson.estimatedDurationFormatted)
                            LessonStatItem(icon: "star.fill", text: "\(lesson.pointsValue ?? 0) XP")

                            if lesson.vocabularyCount > 0 {
                                LessonStatItem(icon: "text.book.closed", text: "\(lesson.vocabularyCount) words")
                            }

                            Spacer()
                        }

                        // Progress Bar (if in progress)
                        if let progress = lesson.userProgress, progress.progressPercentage > 0 {
                            VStack(alignment: .leading, spacing: LLSpacing.xs) {
                                HStack {
                                    Text("Progress")
                                        .font(LLTypography.captionSmall())
                                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                                    Spacer()

                                    Text("\(Int(progress.progressPercentage))%")
                                        .font(LLTypography.captionSmall())
                                        .foregroundColor(LLColors.primary.color(for: colorScheme))
                                        .fontWeight(.semibold)
                                }

                                ProgressBar(value: progress.progressPercentage / 100)
                            }
                        }
                    }
                    .padding(LLSpacing.md)
                }
            }
    }
}

// MARK: - Lesson Grid Card

@MainActor
private struct LessonGridCard: View {
    let lesson: Lesson
    @Binding var showPaywall: Bool

    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false

    var body: some View {
        Group {
            if lesson.isLockedByPaywall {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showPaywall = true
                }) {
                    gridCardContent
                }
            } else {
                NavigationLink(destination: LessonDetailView(
                    roadmapId: lesson.roadmapId,
                    lessonId: lesson.id
                )) {
                    gridCardContent
                }
            }
        }
        .buttonStyle(ScalableButtonStyle(isPressed: $isPressed, scale: 0.95))
        .opacity(lesson.isLockedByPaywall ? 0.8 : 1.0)
    }

    private var gridCardContent: some View {
        LLCard(style: .elevated, padding: .md) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                // Status and Number
                HStack {
                    LessonNumberBadge(number: lesson.lessonNumber, status: lesson.status)
                    Spacer()
                    if lesson.isLockedByPaywall {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(LLColors.warning.color(for: colorScheme))
                    } else {
                        StatusIcon(status: lesson.status)
                    }
                }

                // Title
                Text(lesson.title)
                    .font(LLTypography.bodySmall())
                    .fontWeight(.semibold)
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Badges
                if lesson.requiresPremium {
                    LLBadge("Premium", variant: .warning, size: .sm)
                } else {
                    LLBadge(lesson.category.displayName, variant: .info, size: .sm)
                }

                // Stats
                HStack(spacing: LLSpacing.sm) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(lesson.estimatedDurationFormatted)
                        .font(LLTypography.captionSmall())

                    Spacer()

                    DifficultyBadge(difficulty: lesson.difficulty)
                }
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
            .frame(height: 150)
        }
    }
}

// MARK: - Supporting Components

private struct LessonNumberBadge: View {
    let number: Int
    let status: LessonStatus

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Text("L\(number)")
            .font(LLTypography.h4())
            .fontWeight(.bold)
            .foregroundColor(badgeForeground)
            .frame(width: 48, height: 48)
            .background(
                Circle()
                    .fill(badgeColor)
            )
            .overlay(
                Circle()
                    .strokeBorder(LLColors.border.color(for: colorScheme).opacity(0.6), lineWidth: 2)
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

    private var badgeForeground: Color {
        switch status {
        case .completed:
            return LLColors.successForeground.color(for: colorScheme)
        case .inProgress:
            return LLColors.warningForeground.color(for: colorScheme)
        case .available, .notStarted:
            return LLColors.primaryForeground.color(for: colorScheme)
        case .locked:
            return LLColors.primaryForeground.color(for: colorScheme)
        }
    }
}

private struct StatusIcon: View {
    let status: LessonStatus

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Image(systemName: status.icon)
            .font(.system(size: 20))
            .foregroundColor(iconColor)
    }

    private var iconColor: Color {
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

private struct DifficultyBadge: View {
    let difficulty: Int

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Image(systemName: index < min(difficulty / 2, 5) ? "star.fill" : "star")
                    .font(.system(size: 10))
                    .foregroundColor(LLColors.warning.color(for: colorScheme))
            }
        }
    }
}

private struct LessonStatItem: View {
    let icon: String
    let text: String

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: LLSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(LLTypography.captionSmall())
        }
        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
    }
}

private struct ProgressBar: View {
    let value: Double

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: LLSpacing.radiusFull)
                    .fill(LLColors.muted.color(for: colorScheme))
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: LLSpacing.radiusFull)
                    .fill(LLColors.primary.color(for: colorScheme))
                    .frame(width: geometry.size.width * value, height: 6)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: value)
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Custom Button Styles

struct PressableButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { newValue in
                isPressed = newValue
            }
    }
}

struct ScalableButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    let scale: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Preview

#Preview("Lesson List") {
    NavigationStack {
        LessonListView(
            roadmapId: "test-roadmap",
            cefrLevel: .a1,
            languageName: "Spanish"
        )
    }
}
