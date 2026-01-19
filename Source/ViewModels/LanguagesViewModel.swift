//
//  LanguagesViewModel.swift
//  LanguageLuid
//
//  ViewModel for managing languages, roadmaps, and curriculum
//

import Foundation
import SwiftUI
import os.log

@MainActor
class LanguagesViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var languages: [Language] = []
    @Published var roadmaps: [Roadmap] = []
    @Published var selectedRoadmap: Roadmap?
    @Published var roadmapStats: RoadmapStats?

    @Published var curriculumGroups: [CurriculumGroup] = []
    @Published var filteredGroups: [CurriculumGroup] = []
    @Published var selectedGroup: CurriculumGroup?

    @Published var regionalVariants: [RegionalVariant] = []
    @Published var selectedVariant: RegionalVariant?

    @Published var cefrProgress: [String: CEFRProgress] = [:]
    @Published var selectedCEFRLevel: CEFRLevel?

    @Published var isLoading = false
    @Published var isLoadingGroups = false
    @Published var isLoadingVariants = false
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private let languageService: LanguageService
    private let logger = OSLog(subsystem: "com.luid.languageluid", category: "LanguagesViewModel")

    // MARK: - Initialization

    init(languageService: LanguageService = .shared) {
        self.languageService = languageService
    }

    // MARK: - Languages

    /// Load all available languages
    func loadLanguages() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        NSLog("📚 Loading languages...")
        os_log("📚 Loading languages...", log: logger, type: .info)

        do {
            languages = try await languageService.fetchAllLanguages()
            NSLog("✅ Loaded \(languages.count) languages")
            os_log("✅ Loaded %{public}d languages", log: logger, type: .info, languages.count)
        } catch {
            NSLog("❌ Failed to load languages: \(error.localizedDescription)")
            os_log("❌ Failed to load languages: %{public}@", log: logger, type: .error, error.localizedDescription)
            errorMessage = "Failed to load languages: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Get language by code
    func getLanguage(byCode code: String) -> Language? {
        languages.first { $0.code.lowercased() == code.lowercased() }
    }

    /// Get language by ID
    func getLanguage(byId id: String) -> Language? {
        languages.first { $0.id == id }
    }

    // MARK: - Roadmaps

    /// Load all roadmaps
    func loadRoadmaps(publishedOnly: Bool = true) async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        NSLog("🗺️ Loading roadmaps...")
        os_log("🗺️ Loading roadmaps...", log: logger, type: .info)

        do {
            roadmaps = try await languageService.fetchRoadmaps(
                publishedOnly: publishedOnly,
                includeStats: false
            )
            NSLog("✅ Loaded \(roadmaps.count) roadmaps")
            os_log("✅ Loaded %{public}d roadmaps", log: logger, type: .info, roadmaps.count)
        } catch {
            NSLog("❌ Failed to load roadmaps: \(error.localizedDescription)")
            os_log("❌ Failed to load roadmaps: %{public}@", log: logger, type: .error, error.localizedDescription)
            errorMessage = "Failed to load roadmaps: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Load roadmap by slug or language code
    func loadRoadmap(
        bySlug slug: String,
        includeGroups: Bool = false,
        includeLessons: Bool = false
    ) async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        NSLog("🗺️ Loading roadmap: \(slug)...")
        os_log("🗺️ Loading roadmap: %{public}@", log: logger, type: .info, slug)

        do {
            let roadmap = try await languageService.fetchRoadmap(
                bySlug: slug,
                includeGroups: includeGroups,
                includeLessons: includeLessons
            )
            selectedRoadmap = roadmap

            // Update curriculum groups if included
            if let groups = roadmap.curriculumGroups {
                curriculumGroups = groups
                filteredGroups = groups
            }

            NSLog("✅ Loaded roadmap: \(roadmap.name)")
            os_log("✅ Loaded roadmap: %{public}@", log: logger, type: .info, roadmap.name)
        } catch {
            NSLog("❌ Failed to load roadmap: \(error.localizedDescription)")
            os_log("❌ Failed to load roadmap: %{public}@", log: logger, type: .error, error.localizedDescription)
            errorMessage = "Failed to load roadmap: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Select a roadmap and load its details
    func selectRoadmap(_ roadmap: Roadmap) async {
        selectedRoadmap = roadmap

        // Load additional details
        await loadRoadmapStats(roadmapId: roadmap.id)
        await loadCurriculumGroups(roadmapId: roadmap.id)
        await loadRegionalVariants(roadmapId: roadmap.id)
    }

    /// Load roadmap statistics
    func loadRoadmapStats(roadmapId: String) async {
        NSLog("📊 Loading roadmap stats...")
        os_log("📊 Loading roadmap stats...", log: logger, type: .info)

        do {
            roadmapStats = try await languageService.fetchRoadmapStats(roadmapId: roadmapId)
            NSLog("✅ Loaded roadmap stats")
            os_log("✅ Loaded roadmap stats", log: logger, type: .info)
        } catch {
            NSLog("❌ Failed to load roadmap stats: \(error.localizedDescription)")
            os_log("❌ Failed to load roadmap stats: %{public}@", log: logger, type: .error, error.localizedDescription)
        }
    }

    /// Load CEFR progress for roadmap
    func loadCEFRProgress(roadmapId: String, includeLessons: Bool = false) async {
        NSLog("📊 Loading CEFR progress...")
        os_log("📊 Loading CEFR progress...", log: logger, type: .info)

        do {
            cefrProgress = try await languageService.fetchCEFRProgress(
                roadmapId: roadmapId,
                includeLessons: includeLessons
            )
            NSLog("✅ Loaded CEFR progress for \(cefrProgress.count) levels")
            os_log("✅ Loaded CEFR progress for %{public}d levels", log: logger, type: .info, cefrProgress.count)
        } catch {
            NSLog("❌ Failed to load CEFR progress: \(error.localizedDescription)")
            os_log("❌ Failed to load CEFR progress: %{public}@", log: logger, type: .error, error.localizedDescription)
        }
    }

    // MARK: - Curriculum Groups

    /// Load curriculum groups for a roadmap
    func loadCurriculumGroups(
        roadmapId: String,
        cefrLevel: CEFRLevel? = nil,
        includeLessons: Bool = false
    ) async {
        guard !isLoadingGroups else { return }

        isLoadingGroups = true

        NSLog("📚 Loading curriculum groups...")
        os_log("📚 Loading curriculum groups...", log: logger, type: .info)

        do {
            curriculumGroups = try await languageService.fetchCurriculumGroups(
                roadmapId: roadmapId,
                cefrLevel: cefrLevel,
                includeLessons: includeLessons
            )
            filteredGroups = curriculumGroups
            NSLog("✅ Loaded \(curriculumGroups.count) curriculum groups")
            os_log("✅ Loaded %{public}d curriculum groups", log: logger, type: .info, curriculumGroups.count)
        } catch {
            NSLog("❌ Failed to load curriculum groups: \(error.localizedDescription)")
            os_log("❌ Failed to load curriculum groups: %{public}@", log: logger, type: .error, error.localizedDescription)
            errorMessage = "Failed to load curriculum groups: \(error.localizedDescription)"
        }

        isLoadingGroups = false
    }

    /// Load specific curriculum group
    func loadCurriculumGroup(
        roadmapId: String,
        groupId: String,
        includeLessons: Bool = true
    ) async {
        NSLog("📚 Loading curriculum group: \(groupId)...")
        os_log("📚 Loading curriculum group...", log: logger, type: .info)

        do {
            selectedGroup = try await languageService.fetchCurriculumGroup(
                roadmapId: roadmapId,
                groupId: groupId,
                includeLessons: includeLessons
            )
            NSLog("✅ Loaded curriculum group: \(selectedGroup?.name ?? "")")
            os_log("✅ Loaded curriculum group", log: logger, type: .info)
        } catch {
            NSLog("❌ Failed to load curriculum group: \(error.localizedDescription)")
            os_log("❌ Failed to load curriculum group: %{public}@", log: logger, type: .error, error.localizedDescription)
            errorMessage = "Failed to load curriculum group: \(error.localizedDescription)"
        }
    }

    /// Load Madrigal gap groups
    func loadMadrigalGapGroups(roadmapId: String) async {
        NSLog("🔍 Loading Madrigal gap groups...")
        os_log("🔍 Loading Madrigal gap groups...", log: logger, type: .info)

        do {
            let madrigalGroups = try await languageService.fetchMadrigalGapGroups(roadmapId: roadmapId)
            NSLog("✅ Loaded \(madrigalGroups.count) Madrigal gap groups")
            os_log("✅ Loaded %{public}d Madrigal gap groups", log: logger, type: .info, madrigalGroups.count)
            // Could update a separate property for Madrigal groups if needed
        } catch {
            NSLog("❌ Failed to load Madrigal gap groups: \(error.localizedDescription)")
            os_log("❌ Failed to load Madrigal gap groups: %{public}@", log: logger, type: .error, error.localizedDescription)
        }
    }

    /// Filter groups by CEFR level
    func filterGroupsByLevel(_ level: CEFRLevel?) {
        selectedCEFRLevel = level

        if let level = level {
            filteredGroups = languageService.filterGroups(curriculumGroups, byLevel: level)
            NSLog("🔍 Filtered to \(filteredGroups.count) groups for level \(level.rawValue)")
            os_log("🔍 Filtered to %{public}d groups", log: logger, type: .info, filteredGroups.count)
        } else {
            filteredGroups = curriculumGroups
            NSLog("🔍 Showing all \(filteredGroups.count) groups")
            os_log("🔍 Showing all groups", log: logger, type: .info)
        }
    }

    /// Filter groups by type
    func filterGroupsByType(_ type: GroupType) {
        filteredGroups = languageService.filterGroups(curriculumGroups, byType: type)
        NSLog("🔍 Filtered to \(filteredGroups.count) groups of type \(type.displayName)")
        os_log("🔍 Filtered by type", log: logger, type: .info)
    }

    /// Show only Madrigal gap groups
    func showMadrigalGapGroups() {
        filteredGroups = languageService.filterMadrigalGapGroups(curriculumGroups)
        NSLog("🔍 Showing \(filteredGroups.count) Madrigal gap groups")
        os_log("🔍 Showing Madrigal gap groups", log: logger, type: .info)
    }

    /// Reset group filters
    func resetGroupFilters() {
        selectedCEFRLevel = nil
        filteredGroups = curriculumGroups
        NSLog("🔄 Reset group filters")
        os_log("🔄 Reset group filters", log: logger, type: .info)
    }

    // MARK: - Regional Variants

    /// Load regional variants for a roadmap
    func loadRegionalVariants(roadmapId: String) async {
        guard !isLoadingVariants else { return }

        isLoadingVariants = true

        NSLog("🌍 Loading regional variants...")
        os_log("🌍 Loading regional variants...", log: logger, type: .info)

        do {
            regionalVariants = try await languageService.fetchRegionalVariants(roadmapId: roadmapId)

            // Set default variant if not already selected
            if selectedVariant == nil {
                selectedVariant = languageService.getDefaultVariant(from: regionalVariants)
            }

            NSLog("✅ Loaded \(regionalVariants.count) regional variants")
            os_log("✅ Loaded %{public}d regional variants", log: logger, type: .info, regionalVariants.count)
        } catch {
            NSLog("❌ Failed to load regional variants: \(error.localizedDescription)")
            os_log("❌ Failed to load regional variants: %{public}@", log: logger, type: .error, error.localizedDescription)
        }

        isLoadingVariants = false
    }

    /// Select a regional variant
    func selectVariant(_ variant: RegionalVariant) {
        selectedVariant = variant
        NSLog("🌍 Selected variant: \(variant.name)")
        os_log("🌍 Selected variant: %{public}@", log: logger, type: .info, variant.name)
    }

    // MARK: - Helper Methods

    /// Get roadmap for a language code
    func getRoadmap(forLanguageCode code: String) -> Roadmap? {
        roadmaps.first { roadmap in
            roadmap.language?.code.lowercased() == code.lowercased()
        }
    }

    /// Get groups for a specific CEFR level
    func getGroups(forLevel level: CEFRLevel) -> [CurriculumGroup] {
        languageService.filterGroups(curriculumGroups, byLevel: level)
    }

    /// Get groups by type
    func getGroups(ofType type: GroupType) -> [CurriculumGroup] {
        languageService.filterGroups(curriculumGroups, byType: type)
    }

    /// Get Madrigal gap groups
    var madrigalGapGroups: [CurriculumGroup] {
        languageService.filterMadrigalGapGroups(curriculumGroups)
    }

    /// Get sorted groups
    var sortedGroups: [CurriculumGroup] {
        languageService.sortGroupsByOrder(filteredGroups)
    }

    /// Check if data is loaded
    var hasLanguages: Bool {
        !languages.isEmpty
    }

    var hasRoadmaps: Bool {
        !roadmaps.isEmpty
    }

    var hasGroups: Bool {
        !curriculumGroups.isEmpty
    }

    var hasVariants: Bool {
        !regionalVariants.isEmpty
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }

    /// Reset all data
    func reset() {
        languages = []
        roadmaps = []
        selectedRoadmap = nil
        roadmapStats = nil
        curriculumGroups = []
        filteredGroups = []
        selectedGroup = nil
        regionalVariants = []
        selectedVariant = nil
        cefrProgress = [:]
        selectedCEFRLevel = nil
        errorMessage = nil
        NSLog("🔄 Reset LanguagesViewModel")
        os_log("🔄 Reset LanguagesViewModel", log: logger, type: .info)
    }
}

// MARK: - Preview Helper
// Commented out due to missing mock data
/*
extension LanguagesViewModel {
    static var preview: LanguagesViewModel {
        let vm = LanguagesViewModel()
        vm.languages = Language.mockLanguages
        vm.roadmaps = Roadmap.mockRoadmaps
        vm.selectedRoadmap = Roadmap.mockSpanishRoadmap
        vm.curriculumGroups = CurriculumGroup.mockGroups
        vm.filteredGroups = CurriculumGroup.mockGroups
        vm.regionalVariants = RegionalVariant.mockVariants
        vm.selectedVariant = RegionalVariant.mockSpainSpanish
        vm.roadmapStats = RoadmapStats.mock
        return vm
    }
}
*/
