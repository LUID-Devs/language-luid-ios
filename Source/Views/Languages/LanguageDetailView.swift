//
//  LanguageDetailView.swift
//  LanguageLuid
//
//  Detailed language view with CEFR levels, stats, and curriculum
//  Matches language-luid-frontend/src/app/languages/[slug]/page.tsx
//

import SwiftUI

struct LanguageDetailView: View {
    // MARK: - Properties

    let roadmap: Roadmap

    @StateObject private var viewModel = LanguagesViewModel()
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var selectedLevel: CEFRLevel?
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme

    // MARK: - Computed Properties

    private var cefrLevels: [CEFRLevelData] {
        guard !viewModel.curriculumGroups.isEmpty else { return [] }

        var levels: [CEFRLevelData] = []
        for level in roadmap.cefrLevelsSupported {
            let isUnlocked = levels.last.map { $0.completedLessons >= $0.lessonCount } ?? true
            let levelData = CEFRLevelData.from(
                level: level,
                groups: viewModel.curriculumGroups,
                isUnlocked: isUnlocked
            )
            levels.append(levelData)
        }
        return levels
    }

    private var overallProgress: Double {
        guard !cefrLevels.isEmpty else { return 0 }
        let totalLessons = cefrLevels.reduce(0) { $0 + $1.lessonCount }
        let completedLessons = cefrLevels.reduce(0) { $0 + $1.completedLessons }
        guard totalLessons > 0 else { return 0 }
        return Double(completedLessons) / Double(totalLessons)
    }

    private var stats: LanguageStats {
        let totalLessons = cefrLevels.reduce(0) { $0 + $1.lessonCount }
        let completedLessons = cefrLevels.reduce(0) { $0 + $1.completedLessons }

        return LanguageStats(
            completedLessons: completedLessons,
            totalLessons: totalLessons,
            xpEarned: 0, // TODO: Get from user progress API (not in RoadmapStats)
            accuracy: 0, // TODO: Get from progress
            streak: 0 // TODO: Get from progress
        )
    }

    private var curriculumPreview: [CurriculumGroup] {
        Array(viewModel.curriculumGroups.prefix(6))
    }


    // MARK: - Grid Layout

    private var cefrGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: LLSpacing.md),
            GridItem(.flexible(), spacing: LLSpacing.md)
        ]
    }

    private var curriculumGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: LLSpacing.sm),
            GridItem(.flexible(), spacing: LLSpacing.sm)
        ]
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            LLColors.background.adaptive
                .ignoresSafeArea()

            if isLoading {
                loadingView
            } else if showError {
                errorView
            } else {
                contentView
            }

            NavigationLink(
                destination: Group {
                    if let level = selectedLevel {
                        LessonListView(
                            roadmapId: roadmap.id,
                            cefrLevel: level,
                            languageName: roadmap.languageName
                        )
                    } else {
                        EmptyView()
                    }
                },
                isActive: Binding(
                    get: { selectedLevel != nil },
                    set: { isActive in
                        if !isActive {
                            selectedLevel = nil
                        }
                    }
                )
            ) {
                EmptyView()
            }
            .hidden()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                refreshButton
            }
        }
        .onAppear {
            loadData()
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: LLSpacing.xl) {
                // Header Section
                headerSection

                // Regional Variant Selector
                if !viewModel.regionalVariants.isEmpty && viewModel.regionalVariants.count > 1 {
                    regionalVariantSection
                }

                // Stats Cards
                statsSection

                // CEFR Levels Section
                cefrLevelsSection

                // Curriculum Preview
                if !curriculumPreview.isEmpty {
                    curriculumSection
                }

                // How It Works
                howItWorksSection

                // Backend Info
                backendInfoSection
            }
            .padding(.horizontal, LLSpacing.md)
            .padding(.top, LLSpacing.sm)
            .padding(.bottom, LLSpacing.xl)
        }
        .refreshable {
            await refreshData()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: LLSpacing.md) {
            // Flag and Name
            HStack(alignment: .top, spacing: LLSpacing.md) {
                // Flag
                Text(roadmap.languageFlag)
                    .font(.system(size: 56))

                // Name and Native Name
                VStack(alignment: .leading, spacing: 4) {
                    Text(roadmap.languageName)
                        .font(LLTypography.h1())
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))

                    Text(roadmap.language?.nativeName ?? "")
                        .font(LLTypography.h4())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }

                Spacer()
            }

            // Description
            if let description = roadmap.description {
                Text(description)
                    .font(LLTypography.body())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Regional Variant Section

    private var regionalVariantSection: some View {
        VStack(alignment: .leading, spacing: LLSpacing.sm) {
            HStack(spacing: LLSpacing.xs) {
                Image(systemName: "map.fill")
                    .font(.system(size: 14))
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                Text("Regional Variant")
                    .font(LLTypography.bodySmall())
                    .fontWeight(.semibold)
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LLSpacing.sm) {
                    ForEach(viewModel.regionalVariants) { variant in
                        variantChip(variant)
                    }
                }
            }

            if let variant = viewModel.selectedVariant,
               let description = variant.description {
                Text(description)
                    .font(LLTypography.captionSmall())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
        }
    }

    private func variantChip(_ variant: RegionalVariant) -> some View {
        let isSelected = viewModel.selectedVariant?.id == variant.id

        return Button(action: {
            viewModel.selectVariant(variant)
        }) {
            HStack(spacing: LLSpacing.xs) {
                if let flag = variant.flagEmoji {
                    Text(flag)
                        .font(.system(size: 16))
                }

                Text(variant.name)
                    .font(LLTypography.buttonSmall())

                if variant.isDefault {
                    Text("Default")
                        .font(LLTypography.captionSmall())
                        .foregroundColor(LLColors.secondaryForeground.color(for: colorScheme))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(LLColors.secondary.color(for: colorScheme))
                        )
                }
            }
            .foregroundColor(
                isSelected
                    ? LLColors.primaryForeground.color(for: colorScheme)
                    : LLColors.foreground.color(for: colorScheme)
            )
            .padding(.horizontal, LLSpacing.md)
            .frame(height: 36)
            .background(
                Capsule()
                    .fill(
                        isSelected
                            ? LLColors.primary.color(for: colorScheme)
                            : LLColors.muted.color(for: colorScheme)
                    )
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isSelected ? Color.clear : LLColors.border.color(for: colorScheme),
                        lineWidth: LLSpacing.borderStandard
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: LLSpacing.sm) {
            statCard(
                icon: "book.fill",
                value: "\(stats.totalLessons)",
                label: "Total Lessons"
            )

            statCard(
                icon: "flame.fill",
                value: "\(stats.streak)",
                label: "Day Streak"
            )
        }
    }

    private func statCard(icon: String, value: String, label: String) -> some View {
        VStack(spacing: LLSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            Text(label)
                .font(LLTypography.captionSmall())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LLSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                .fill(LLColors.card.color(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                .strokeBorder(LLColors.border.color(for: colorScheme), lineWidth: LLSpacing.borderStandard)
        )
    }

    // MARK: - CEFR Levels Section

    private var cefrLevelsSection: some View {
        VStack(alignment: .leading, spacing: LLSpacing.md) {
            // Section Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Learning Path")
                        .font(LLTypography.h2())
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))

                    Text("Progress through CEFR levels from beginner to proficient")
                        .font(LLTypography.bodySmall())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }

                Spacer()

                HStack(spacing: LLSpacing.xs) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(LLColors.warning.color(for: colorScheme))

                    Text("CEFR Aligned")
                        .font(LLTypography.captionSmall())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
                .padding(.horizontal, LLSpacing.sm)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .strokeBorder(LLColors.border.color(for: colorScheme), lineWidth: LLSpacing.borderStandard)
                )
            }


            // CEFR Level Cards Grid
            LazyVGrid(columns: cefrGridColumns, spacing: LLSpacing.md) {
                ForEach(Array(cefrLevels.enumerated()), id: \.element.code) { index, level in
                    CEFRLevelCardView(
                        level: level,
                        languageCode: roadmap.slug
                    ) {
                        handleLevelTap(level: level)
                    }
                }
            }
        }
    }

    // MARK: - Curriculum Section

    private var curriculumSection: some View {
        VStack(alignment: .leading, spacing: LLSpacing.md) {
            Text("Curriculum Overview")
                .font(LLTypography.h3())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            LazyVGrid(columns: curriculumGridColumns, spacing: LLSpacing.sm) {
                ForEach(curriculumPreview) { group in
                    curriculumGroupCard(group)
                }
            }

            if viewModel.curriculumGroups.count > 6 {
                Text("+\(viewModel.curriculumGroups.count - 6) more curriculum groups")
                    .font(LLTypography.bodySmall())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private func curriculumGroupCard(_ group: CurriculumGroup) -> some View {
        VStack(alignment: .leading, spacing: LLSpacing.xs) {
            HStack {
                LLBadge(group.cefrLevel.rawValue, variant: .secondary, size: .sm)

                Spacer()

                Text("\(group.totalLessons) lessons")
                    .font(LLTypography.captionSmall())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }

            Text(group.name)
                .font(LLTypography.bodySmall())
                .fontWeight(.semibold)
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                .lineLimit(2)

            if let description = group.description {
                Text(description)
                    .font(LLTypography.captionSmall())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    .lineLimit(2)
            }
        }
        .padding(LLSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                .fill(LLColors.card.color(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                .strokeBorder(LLColors.border.color(for: colorScheme), lineWidth: LLSpacing.borderStandard)
        )
    }

    // MARK: - How It Works Section

    private var howItWorksSection: some View {
        LLCard(style: .filled, padding: .md) {
            HStack(alignment: .top, spacing: LLSpacing.md) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(LLColors.secondary.color(for: colorScheme))
                    )

                VStack(alignment: .leading, spacing: LLSpacing.sm) {
                    Text("How It Works")
                        .font(LLTypography.h4())
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))

                    VStack(alignment: .leading, spacing: LLSpacing.xs) {
                        howItWorksStep(
                            number: 1,
                            text: "Start with A1 (Beginner) and progress through each CEFR level"
                        )

                        howItWorksStep(
                            number: 2,
                            text: "Complete lessons to unlock the next level"
                        )

                        howItWorksStep(
                            number: 3,
                            text: "Each lesson uses our 4-phase method: Pattern Recognition, Sentence Building, Translation Challenge, Conversation Practice"
                        )

                        howItWorksStep(
                            number: 4,
                            text: "Practice pronunciation with AI-powered speech recognition"
                        )
                    }
                }
            }
        }
    }

    private func howItWorksStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: LLSpacing.xs) {
            Text("\(number).")
                .font(LLTypography.bodySmall())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                .frame(minWidth: 20, alignment: .leading)

            Text(text)
                .font(LLTypography.bodySmall())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
    }

    // MARK: - Backend Info Section

    private var backendInfoSection: some View {
        Text("\(stats.totalLessons) lessons loaded from backend API | \(viewModel.curriculumGroups.count) curriculum groups | \(viewModel.regionalVariants.count) regional variants")
            .font(LLTypography.captionSmall())
            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: LLSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(LLColors.primary.adaptive)

            Text("Loading language data...")
                .font(LLTypography.body())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
    }

    // MARK: - Error View

    private var errorView: some View {
        VStack(spacing: LLSpacing.lg) {
            Image(systemName: "globe")
                .font(.system(size: 64))
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

            Text("Language Not Found")
                .font(LLTypography.h2())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            Text(errorMessage ?? "The language you're looking for doesn't exist or isn't available yet.")
                .font(LLTypography.body())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, LLSpacing.xl)

            LLButton("Back to Languages", style: .primary) {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .padding(LLSpacing.xl)
    }

    // MARK: - Refresh Button

    private var refreshButton: some View {
        Button(action: {
            Task {
                await refreshData()
            }
        }) {
            Image(systemName: isLoading ? "arrow.clockwise" : "arrow.clockwise")
                .font(.system(size: 16))
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                .rotationEffect(.degrees(isLoading ? 360 : 0))
                .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
        }
        .disabled(isLoading)
    }

    // MARK: - Data Loading

    private func loadData() {
        guard !roadmap.id.isEmpty else {
            showError = true
            errorMessage = "Invalid roadmap ID"
            isLoading = false
            return
        }

        Task {
            isLoading = true
            showError = false

            // Set the roadmap
            viewModel.selectedRoadmap = roadmap

            // Load curriculum groups (progress comes from CEFR progress API)
            await viewModel.loadCurriculumGroups(roadmapId: roadmap.id, includeLessons: false)

            // Load regional variants
            await viewModel.loadRegionalVariants(roadmapId: roadmap.id)

            // Load roadmap stats
            await viewModel.loadRoadmapStats(roadmapId: roadmap.id)

            // Load CEFR progress
            await viewModel.loadCEFRProgress(roadmapId: roadmap.id)

            if viewModel.curriculumGroups.isEmpty && viewModel.errorMessage != nil {
                showError = true
                errorMessage = viewModel.errorMessage
            }

            isLoading = false
        }
    }

    private func refreshData() async {
        await viewModel.loadCurriculumGroups(roadmapId: roadmap.id, includeLessons: false)
        await viewModel.loadRegionalVariants(roadmapId: roadmap.id)
        await viewModel.loadRoadmapStats(roadmapId: roadmap.id)
        await viewModel.loadCEFRProgress(roadmapId: roadmap.id)
    }

    private func handleLevelTap(level: CEFRLevelData) {
        guard let cefrLevel = CEFRLevel(rawValue: level.code) else { return }
        selectedLevel = cefrLevel
    }
}

// MARK: - Language Stats Model

struct LanguageStats {
    let completedLessons: Int
    let totalLessons: Int
    let xpEarned: Int
    let accuracy: Int
    let streak: Int
}

// MARK: - Preview
// TODO: Fix previews - Roadmap mock data unavailable
/*
#Preview("Language Detail - Spanish") {
    NavigationView {
        LanguageDetailView(roadmap: Roadmap.mockSpanishRoadmap)
    }
}

#Preview("Language Detail - French") {
    NavigationView {
        LanguageDetailView(roadmap: Roadmap.mockFrenchRoadmap)
    }
}
*/
