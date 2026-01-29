//
//  ContinueLearningView.swift
//  LanguageLuid
//
//  Continue Learning hub - Shows in-progress lessons, recent activity, and recommendations
//  Replaces the placeholder Lessons tab
//

import SwiftUI

struct ContinueLearningView: View {
    @StateObject private var viewModel = ContinueLearningViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var tabRouter: TabRouter
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedLesson: LessonWithRoadmap?

    private let gridColumns = [
        GridItem(.flexible(), spacing: LLSpacing.md),
        GridItem(.flexible(), spacing: LLSpacing.md)
    ]

    var body: some View {
        ZStack {
            ScrollView {
                if viewModel.isLoading && !viewModel.hasAnyActivity {
                    loadingView
                } else if !viewModel.hasEnrolledLanguages {
                    noLanguagesView
                } else {
                    contentView
                }
            }
            .background(LLColors.background.adaptive)
            .navigationTitle("Continue Learning")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadAllData()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.dismissError()
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }

            // Hidden NavigationLink for lesson navigation
            NavigationLink(
                destination: Group {
                    if let lesson = selectedLesson {
                        LessonDetailView(
                            roadmapId: lesson.roadmap.id,
                            lessonId: lesson.lesson.id
                        )
                    }
                },
                isActive: Binding(
                    get: { selectedLesson != nil },
                    set: { isActive in
                        if !isActive {
                            selectedLesson = nil
                        }
                    }
                )
            ) {
                EmptyView()
            }
            .hidden()
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        VStack(spacing: LLSpacing.xl) {
            // Header section
            headerSection
                .padding(.horizontal, LLSpacing.md)

            // Hero - Resume most recent lesson
            if let heroLesson = viewModel.heroLesson {
                heroSection(heroLesson)
                    .padding(.horizontal, LLSpacing.md)
            }

            // Other in-progress lessons
            if !viewModel.otherInProgressLessons.isEmpty {
                inProgressSection
            }

            // Recent activity
            if !viewModel.recentlyCompletedLessons.isEmpty {
                recentActivitySection
            }

            // Recommended lessons
            if !viewModel.recommendedLessons.isEmpty {
                recommendedSection
            }

            // Your languages quick access
            if !viewModel.enrolledRoadmaps.isEmpty {
                languagesSection
            }

            // Empty state if no activity
            if !viewModel.hasAnyActivity {
                emptyStateView
                    .padding(.horizontal, LLSpacing.md)
            }
        }
        .padding(.vertical, LLSpacing.md)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: LLSpacing.sm) {
            Text("Welcome back, \(authViewModel.userDisplayName)!")
                .font(LLTypography.h3())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            Text(formattedDate)
                .font(LLTypography.body())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

            // Quick stats row
            HStack(spacing: LLSpacing.lg) {
                statItem(
                    icon: "flame.fill",
                    value: "\(authViewModel.currentUser?.currentStreak ?? 0)",
                    label: "Day Streak",
                    color: LLColors.destructive.color(for: colorScheme)
                )

                statItem(
                    icon: "trophy.fill",
                    value: "\(authViewModel.currentUser?.totalXp ?? 0)",
                    label: "Total XP",
                    color: LLColors.warning.color(for: colorScheme)
                )

                statItem(
                    icon: "book.fill",
                    value: "\(authViewModel.currentUser?.lessonsCompleted ?? 0)",
                    label: "Completed",
                    color: LLColors.primary.color(for: colorScheme)
                )
            }
            .padding(.top, LLSpacing.sm)
        }
    }

    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: LLSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(LLTypography.h4())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))

                Text(label)
                    .font(LLTypography.captionSmall())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    // MARK: - Hero Section

    private func heroSection(_ heroLesson: LessonWithRoadmap) -> some View {
        VStack(alignment: .leading, spacing: LLSpacing.md) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(LLColors.primary.color(for: colorScheme))

                Text("Pick Up Where You Left Off")
                    .font(LLTypography.h3())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))

                Spacer()
            }

            LessonProgressCard(
                lessonWithRoadmap: heroLesson,
                style: .hero,
                onTap: {
                    navigateToLesson(heroLesson)
                }
            )
        }
    }

    // MARK: - In Progress Section

    private var inProgressSection: some View {
        VStack(alignment: .leading, spacing: LLSpacing.md) {
            HStack {
                Image(systemName: "book.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(LLColors.primary.color(for: colorScheme))

                Text("Continue Learning")
                    .font(LLTypography.h3())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))

                Spacer()

                Text("\(viewModel.otherInProgressLessons.count)")
                    .font(LLTypography.bodyMedium())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
            .padding(.horizontal, LLSpacing.md)

            LazyVGrid(columns: gridColumns, spacing: LLSpacing.md) {
                ForEach(viewModel.otherInProgressLessons) { lessonWithRoadmap in
                    LessonProgressCard(
                        lessonWithRoadmap: lessonWithRoadmap,
                        style: .standard,
                        onTap: {
                            navigateToLesson(lessonWithRoadmap)
                        }
                    )
                }
            }
            .padding(.horizontal, LLSpacing.md)
        }
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: LLSpacing.md) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 20))
                    .foregroundColor(LLColors.success.color(for: colorScheme))

                Text("Recent Activity")
                    .font(LLTypography.h3())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))

                Spacer()
            }
            .padding(.horizontal, LLSpacing.md)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.recentlyCompletedLessons.enumerated()), id: \.element.id) { index, lessonWithRoadmap in
                    ActivityTimelineItem(
                        lessonWithRoadmap: lessonWithRoadmap,
                        isLast: index == viewModel.recentlyCompletedLessons.count - 1,
                        onTap: {
                            navigateToLesson(lessonWithRoadmap)
                        }
                    )
                }
            }
            .padding(LLSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                    .fill(LLColors.card.color(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                    .strokeBorder(LLColors.border.color(for: colorScheme), lineWidth: LLSpacing.borderStandard)
            )
            .padding(.horizontal, LLSpacing.md)
        }
    }

    // MARK: - Recommended Section

    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: LLSpacing.md) {
            HStack {
                Image(systemName: "lightbulb.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(LLColors.warning.color(for: colorScheme))

                Text("Recommended For You")
                    .font(LLTypography.h3())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))

                Spacer()
            }
            .padding(.horizontal, LLSpacing.md)

            LazyVGrid(columns: gridColumns, spacing: LLSpacing.md) {
                ForEach(viewModel.recommendedLessons) { lessonWithRoadmap in
                    LessonProgressCard(
                        lessonWithRoadmap: lessonWithRoadmap,
                        style: .compact,
                        onTap: {
                            navigateToLesson(lessonWithRoadmap)
                        }
                    )
                }
            }
            .padding(.horizontal, LLSpacing.md)
        }
    }

    // MARK: - Languages Section

    private var languagesSection: some View {
        VStack(alignment: .leading, spacing: LLSpacing.md) {
            HStack {
                Image(systemName: "globe")
                    .font(.system(size: 20))
                    .foregroundColor(LLColors.primary.color(for: colorScheme))

                Text("Your Languages")
                    .font(LLTypography.h3())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))

                Spacer()

                Button {
                    tabRouter.selectedTab = .languages
                } label: {
                    Text("View All")
                        .font(LLTypography.bodySmall())
                        .foregroundColor(LLColors.primary.color(for: colorScheme))
                }
            }
            .padding(.horizontal, LLSpacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LLSpacing.md) {
                    ForEach(viewModel.enrolledRoadmaps) { roadmap in
                        languageCard(roadmap)
                    }
                }
                .padding(.horizontal, LLSpacing.md)
            }
        }
    }

    private func languageCard(_ roadmap: Roadmap) -> some View {
        NavigationLink(destination: LanguageDetailView(roadmap: roadmap)) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                // Flag
                Text(roadmap.languageFlag)
                    .font(.system(size: 32))

                // Language name
                Text(roadmap.languageName)
                    .font(LLTypography.h4())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
                    .lineLimit(1)

                Spacer()

                // Progress
                if let progress = viewModel.getProgress(for: roadmap.id) {
                    VStack(alignment: .leading, spacing: LLSpacing.xs) {
                        Text("\(progress.completedLessons)/\(progress.totalLessons) lessons")
                            .font(LLTypography.captionSmall())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                        ProgressView(value: Double(progress.completedLessons), total: Double(progress.totalLessons))
                            .tint(LLColors.primary.color(for: colorScheme))
                    }
                }
            }
            .padding(LLSpacing.md)
            .frame(width: 160, height: 140)
            .background(
                RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                    .fill(LLColors.card.color(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                    .strokeBorder(LLColors.border.color(for: colorScheme), lineWidth: LLSpacing.borderStandard)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: LLSpacing.lg) {
            Image(systemName: "book.circle")
                .font(.system(size: 64))
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

            Text("Start Your Learning Journey")
                .font(LLTypography.h3())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            Text("Choose a language and start your first lesson to begin tracking your progress here.")
                .font(LLTypography.body())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, LLSpacing.xl)

            LLButton("Browse Languages", style: .primary) {
                tabRouter.selectedTab = .languages
            }
        }
        .padding(.vertical, LLSpacing.xl)
    }

    // MARK: - No Languages View

    private var noLanguagesView: some View {
        VStack(spacing: LLSpacing.lg) {
            Image(systemName: "globe.americas.fill")
                .font(.system(size: 64))
                .foregroundColor(LLColors.primary.color(for: colorScheme))

            Text("Choose Your Language")
                .font(LLTypography.h3())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            Text("Browse available languages and start learning today!")
                .font(LLTypography.body())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, LLSpacing.xl)

            LLButton("Browse Languages", style: .primary) {
                tabRouter.selectedTab = .languages
            }
        }
        .padding(.vertical, LLSpacing.xl)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: LLSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(LLColors.primary.adaptive)

            Text("Loading your lessons...")
                .font(LLTypography.body())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    // MARK: - Navigation

    private func navigateToLesson(_ lessonWithRoadmap: LessonWithRoadmap) {
        selectedLesson = lessonWithRoadmap
    }
}

// MARK: - Preview
// TODO: Fix preview - needs mock AuthViewModel
/*
#Preview("Continue Learning View") {
    NavigationStack {
        ContinueLearningView()
            .environmentObject(AuthViewModel.mock())
            .environmentObject(TabRouter())
    }
}
*/
