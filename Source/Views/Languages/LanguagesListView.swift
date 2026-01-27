//
//  LanguagesListView.swift
//  LanguageLuid
//
//  Language browser screen with grid layout, search, and filtering
//  Matches language-luid-frontend design
//

import SwiftUI

struct LanguagesListView: View {
    // MARK: - Properties

    @StateObject private var viewModel = LanguagesViewModel()
    @State private var searchText = ""
    @State private var selectedFilter: DifficultyFilter = .all
    @State private var isRefreshing = false
    @Environment(\.colorScheme) var colorScheme

    // MARK: - Filter Options

    enum DifficultyFilter: String, CaseIterable {
        case all = "All"
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"

        var languageDifficulty: LanguageDifficulty? {
            switch self {
            case .all: return nil
            case .beginner: return .beginner
            case .intermediate: return .intermediate
            case .advanced: return .advanced
            }
        }
    }

    // MARK: - Computed Properties

    private var filteredRoadmaps: [Roadmap] {
        var roadmaps = viewModel.roadmaps

        // Apply search filter
        if !searchText.isEmpty {
            roadmaps = roadmaps.filter { roadmap in
                let language = roadmap.language
                return language?.name.localizedCaseInsensitiveContains(searchText) ?? false ||
                       language?.nativeName.localizedCaseInsensitiveContains(searchText) ?? false ||
                       roadmap.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply difficulty filter
        if let difficulty = selectedFilter.languageDifficulty {
            roadmaps = roadmaps.filter { roadmap in
                roadmap.language?.difficulty == difficulty
            }
        }

        return roadmaps
    }

    private var popularRoadmaps: [Roadmap] {
        viewModel.roadmaps
            .sorted { ($0.language?.popularity ?? 999) < ($1.language?.popularity ?? 999) }
            .prefix(6)
            .map { $0 }
    }

    private var hasResults: Bool {
        !filteredRoadmaps.isEmpty
    }

    // MARK: - Grid Layout

    private var gridColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 160, maximum: 200), spacing: LLSpacing.md)
        ]
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                LLColors.background.adaptive
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.roadmaps.isEmpty {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(message: error)
                } else {
                    contentView
                }
            }
            .navigationTitle("Languages")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if viewModel.roadmaps.isEmpty {
                Task {
                    await viewModel.loadRoadmaps(publishedOnly: true)
                }
            }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: LLSpacing.xl) {
                // Search Bar
                searchBar

                // Filter Chips
                filterChips

                // Popular Languages Section
                if searchText.isEmpty && selectedFilter == .all && !popularRoadmaps.isEmpty {
                    popularSection
                }

                // All Languages Grid
                if hasResults {
                    languagesGrid
                } else {
                    emptyStateView
                }
            }
            .padding(.horizontal, LLSpacing.md)
            .padding(.top, LLSpacing.sm)
            .padding(.bottom, LLSpacing.xl)
        }
        .refreshable {
            await refreshData()
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: LLSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                .frame(width: LLSpacing.iconMD, height: LLSpacing.iconMD)

            TextField("Search languages...", text: $searchText)
                .font(LLTypography.body())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                .autocapitalization(.none)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        .frame(width: LLSpacing.iconMD, height: LLSpacing.iconMD)
                }
            }
        }
        .padding(.horizontal, LLSpacing.md)
        .frame(height: LLSpacing.inputHeight)
        .background(
            RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                .fill(LLColors.card.color(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                .strokeBorder(LLColors.border.color(for: colorScheme), lineWidth: LLSpacing.borderStandard)
        )
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LLSpacing.sm) {
                ForEach(DifficultyFilter.allCases, id: \.self) { filter in
                    filterChip(for: filter)
                }
            }
        }
    }

    private func filterChip(for filter: DifficultyFilter) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedFilter = filter
            }
        }) {
            Text(filter.rawValue)
                .font(LLTypography.buttonSmall())
                .foregroundColor(
                    selectedFilter == filter
                        ? LLColors.primaryForeground.color(for: colorScheme)
                        : LLColors.foreground.color(for: colorScheme)
                )
                .padding(.horizontal, LLSpacing.md)
                .frame(height: 36)
                .background(
                    Capsule()
                        .fill(
                            selectedFilter == filter
                                ? LLColors.primary.color(for: colorScheme)
                                : LLColors.muted.color(for: colorScheme)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Popular Section

    private var popularSection: some View {
        VStack(alignment: .leading, spacing: LLSpacing.md) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 16))
                    .foregroundColor(LLColors.warning.color(for: colorScheme))

                Text("Popular Languages")
                    .font(LLTypography.h3())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))

                Spacer()
            }

            LazyVGrid(columns: gridColumns, spacing: LLSpacing.md) {
                ForEach(popularRoadmaps) { roadmap in
                    NavigationLink(destination: LanguageDetailView(roadmap: roadmap)) {
                        LanguageCard(roadmap: roadmap, isPopular: true)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - Languages Grid

    private var languagesGrid: some View {
        VStack(alignment: .leading, spacing: LLSpacing.md) {
            if !searchText.isEmpty || selectedFilter != .all {
                HStack {
                    Text("\(filteredRoadmaps.count) language\(filteredRoadmaps.count == 1 ? "" : "s")")
                        .font(LLTypography.h3())
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))

                    Spacer()
                }
            }

            LazyVGrid(columns: gridColumns, spacing: LLSpacing.md) {
                ForEach(filteredRoadmaps) { roadmap in
                    NavigationLink(destination: LanguageDetailView(roadmap: roadmap)) {
                        LanguageCard(roadmap: roadmap, isPopular: false)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: LLSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(LLColors.primary.adaptive)

            Text("Loading languages...")
                .font(LLTypography.body())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: LLSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(LLColors.warning.color(for: colorScheme))

            Text("Error Loading Languages")
                .font(LLTypography.h2())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            Text(message)
                .font(LLTypography.body())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, LLSpacing.xl)

            LLButton("Try Again", style: .primary) {
                Task {
                    await viewModel.loadRoadmaps(publishedOnly: true)
                }
            }
        }
        .padding(LLSpacing.xl)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: LLSpacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

            Text("No languages found")
                .font(LLTypography.h3())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            Text("Try adjusting your search or filters")
                .font(LLTypography.body())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

            if !searchText.isEmpty || selectedFilter != .all {
                LLButton("Clear Filters", style: .outline, size: .sm) {
                    searchText = ""
                    selectedFilter = .all
                }
            }
        }
        .padding(LLSpacing.xl)
    }

    // MARK: - Helper Methods

    private func refreshData() async {
        isRefreshing = true
        await viewModel.loadRoadmaps(publishedOnly: true)
        isRefreshing = false
    }
}

// MARK: - Language Card Component

struct LanguageCard: View {
    let roadmap: Roadmap
    let isPopular: Bool

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: LLSpacing.sm) {
            // Flag and Popular Badge
            HStack(alignment: .top) {
                Text(roadmap.languageFlag)
                    .font(.system(size: 40))

                Spacer()

                if isPopular {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(LLColors.warning.color(for: colorScheme))
                }
            }

            // Language Name
            VStack(alignment: .leading, spacing: 4) {
                Text(roadmap.languageName)
                    .font(LLTypography.h4())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
                    .lineLimit(1)

                Text(roadmap.language?.nativeName ?? "")
                    .font(LLTypography.bodySmall())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    .lineLimit(1)
            }

            // Difficulty Badge
            if let language = roadmap.language, let difficulty = language.difficulty {
                LLBadge(
                    difficulty.displayName,
                    variant: difficultyVariant(for: difficulty),
                    size: .sm
                )
            }

            // Brief Description
            if let description = roadmap.description {
                Text(description)
                    .font(LLTypography.captionSmall())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    .lineLimit(2)
                    .frame(height: 32)
            }

            Spacer()

            // Start Learning Button
            HStack {
                Spacer()

                Text("Start Learning")
                    .font(LLTypography.buttonSmall())
                    .foregroundColor(LLColors.primaryForeground.color(for: colorScheme))
                    .padding(.horizontal, LLSpacing.sm)
                    .padding(.vertical, LLSpacing.xs)
                    .background(
                        Capsule()
                            .fill(LLColors.primary.color(for: colorScheme))
                    )

                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(LLColors.primaryForeground.color(for: colorScheme))
            }
        }
        .padding(LLSpacing.md)
        .frame(height: 240)
        .background(
            RoundedRectangle(cornerRadius: LLSpacing.radiusLG)
                .fill(LLColors.card.color(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LLSpacing.radiusLG)
                .strokeBorder(LLColors.border.color(for: colorScheme), lineWidth: LLSpacing.borderStandard)
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05),
            radius: LLSpacing.shadowSMRadius,
            x: 0,
            y: LLSpacing.shadowSM
        )
    }

    private func difficultyVariant(for difficulty: LanguageDifficulty) -> LLBadgeVariant {
        switch difficulty {
        case .beginner: return .success
        case .intermediate: return .info
        case .advanced: return .warning
        }
    }
}

// MARK: - Preview

#Preview("Languages List") {
    LanguagesListView()
}

// TODO: Fix preview - Roadmap mock data unavailable
/*
#Preview("Language Card") {
    VStack(spacing: LLSpacing.md) {
        LanguageCard(roadmap: Roadmap.mockSpanishRoadmap, isPopular: true)
        LanguageCard(roadmap: Roadmap.mockFrenchRoadmap, isPopular: false)
    }
    .padding()
}
*/
