//
//  LanguageService.swift
//  LanguageLuid
//
//  Service for language roadmaps, curriculum groups, and regional variants
//  Matches backend routes from roadmap.routes.js
//

import Foundation
import os.log

// MARK: - API Response Wrappers

struct LanguagesResponse: Codable {
    let success: Bool
    let data: [Language]
}

struct RoadmapsResponse: Codable {
    let success: Bool
    let data: [Roadmap]
}

struct RoadmapResponse: Codable {
    let success: Bool
    let data: Roadmap
}

struct CurriculumGroupsResponse: Codable {
    let success: Bool
    let data: [CurriculumGroup]
}

struct CurriculumGroupResponse: Codable {
    let success: Bool
    let data: CurriculumGroup
}

struct RegionalVariantsResponse: Codable {
    let success: Bool
    let data: [RegionalVariant]
}

struct RoadmapStatsResponse: Codable {
    let success: Bool
    let data: RoadmapStats
}

struct CEFRProgressResponse: Codable {
    let success: Bool
    let data: [String: CEFRProgress]
}

// MARK: - Language Service

@MainActor
class LanguageService {
    static let shared = LanguageService()

    private let apiClient: APIClient
    private let logger = OSLog(subsystem: "com.luid.languageluid", category: "LanguageService")

    private init() {
        self.apiClient = APIClient.shared
    }

    // MARK: - Languages

    /// Fetch all active languages
    /// GET /api/languages
    func fetchAllLanguages() async throws -> [Language] {
        NSLog("🌐 Fetching all languages...")
        os_log("🌐 Fetching all languages...", log: logger, type: .info)

        do {
            let response: LanguagesResponse = try await apiClient.get(
                APIEndpoint.languages,
                requiresAuth: false
            )

            NSLog("✅ Fetched \(response.data.count) languages")
            os_log("✅ Fetched %{public}d languages", log: logger, type: .info, response.data.count)

            return response.data
        } catch {
            NSLog("❌ Failed to fetch languages: \(error.localizedDescription)")
            os_log("❌ Failed to fetch languages: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    // MARK: - Roadmaps

    /// Fetch all active roadmaps
    /// GET /api/roadmaps
    /// - Parameters:
    ///   - publishedOnly: Only return published roadmaps (default: true)
    ///   - includeStats: Include roadmap statistics (default: false)
    func fetchRoadmaps(publishedOnly: Bool = true, includeStats: Bool = false) async throws -> [Roadmap] {
        NSLog("🗺️ Fetching roadmaps (publishedOnly: \(publishedOnly))...")
        os_log("🗺️ Fetching roadmaps...", log: logger, type: .info)

        var parameters: [String: Any] = [:]
        if publishedOnly {
            parameters["publishedOnly"] = "true"
        }
        if includeStats {
            parameters["includeStats"] = "true"
        }

        do {
            let response: RoadmapsResponse = try await apiClient.get(
                APIEndpoint.roadmaps,
                parameters: parameters,
                requiresAuth: false
            )

            NSLog("✅ Fetched \(response.data.count) roadmaps")
            os_log("✅ Fetched %{public}d roadmaps", log: logger, type: .info, response.data.count)

            return response.data
        } catch {
            NSLog("❌ Failed to fetch roadmaps: \(error.localizedDescription)")
            os_log("❌ Failed to fetch roadmaps: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    /// Fetch roadmap by slug or language code
    /// GET /api/roadmaps/slug/:slug
    /// - Parameters:
    ///   - slug: Roadmap slug (e.g., "spanish-roadmap") or language code (e.g., "es")
    ///   - includeGroups: Include curriculum groups (default: false)
    ///   - includeLessons: Include lessons (default: false)
    func fetchRoadmap(
        bySlug slug: String,
        includeGroups: Bool = false,
        includeLessons: Bool = false
    ) async throws -> Roadmap {
        NSLog("🗺️ Fetching roadmap by slug: \(slug)...")
        os_log("🗺️ Fetching roadmap by slug: %{public}@", log: logger, type: .info, slug)

        var parameters: [String: Any] = [:]
        if includeGroups {
            parameters["includeGroups"] = "true"
        }
        if includeLessons {
            parameters["includeLessons"] = "true"
        }

        do {
            let response: RoadmapResponse = try await apiClient.get(
                "\(APIEndpoint.roadmaps)/slug/\(slug)",
                parameters: parameters,
                requiresAuth: false
            )

            NSLog("✅ Fetched roadmap: \(response.data.name)")
            os_log("✅ Fetched roadmap: %{public}@", log: logger, type: .info, response.data.name)

            return response.data
        } catch {
            NSLog("❌ Failed to fetch roadmap by slug: \(error.localizedDescription)")
            os_log("❌ Failed to fetch roadmap by slug: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    /// Fetch roadmap by ID
    /// GET /api/roadmaps/:roadmapId
    /// - Parameters:
    ///   - roadmapId: Roadmap UUID
    ///   - includeGroups: Include curriculum groups (default: false)
    ///   - includeLessons: Include lessons (default: false)
    func fetchRoadmap(
        byId roadmapId: String,
        includeGroups: Bool = false,
        includeLessons: Bool = false
    ) async throws -> Roadmap {
        NSLog("🗺️ Fetching roadmap by ID: \(roadmapId)...")
        os_log("🗺️ Fetching roadmap by ID: %{public}@", log: logger, type: .info, roadmapId)

        var parameters: [String: Any] = [:]
        if includeGroups {
            parameters["includeGroups"] = "true"
        }
        if includeLessons {
            parameters["includeLessons"] = "true"
        }

        do {
            let response: RoadmapResponse = try await apiClient.get(
                "\(APIEndpoint.roadmaps)/\(roadmapId)",
                parameters: parameters,
                requiresAuth: false
            )

            NSLog("✅ Fetched roadmap: \(response.data.name)")
            os_log("✅ Fetched roadmap: %{public}@", log: logger, type: .info, response.data.name)

            return response.data
        } catch {
            NSLog("❌ Failed to fetch roadmap by ID: \(error.localizedDescription)")
            os_log("❌ Failed to fetch roadmap by ID: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    /// Fetch roadmap statistics
    /// GET /api/roadmaps/:roadmapId/stats
    /// - Parameter roadmapId: Roadmap UUID
    func fetchRoadmapStats(roadmapId: String) async throws -> RoadmapStats {
        NSLog("📊 Fetching roadmap stats for: \(roadmapId)...")
        os_log("📊 Fetching roadmap stats...", log: logger, type: .info)

        do {
            let response: RoadmapStatsResponse = try await apiClient.get(
                "\(APIEndpoint.roadmaps)/\(roadmapId)/stats",
                requiresAuth: false
            )

            NSLog("✅ Fetched roadmap stats: \(response.data.totalLessons) lessons")
            os_log("✅ Fetched roadmap stats: %{public}d lessons", log: logger, type: .info, response.data.totalLessons)

            return response.data
        } catch {
            NSLog("❌ Failed to fetch roadmap stats: \(error.localizedDescription)")
            os_log("❌ Failed to fetch roadmap stats: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    /// Fetch CEFR progress for roadmap
    /// GET /api/roadmaps/:roadmapId/cefr-progress
    /// - Parameters:
    ///   - roadmapId: Roadmap UUID
    ///   - includeLessons: Include lessons for each level (default: false)
    func fetchCEFRProgress(
        roadmapId: String,
        includeLessons: Bool = false
    ) async throws -> [String: CEFRProgress] {
        NSLog("📊 Fetching CEFR progress for: \(roadmapId)...")
        os_log("📊 Fetching CEFR progress...", log: logger, type: .info)

        var parameters: [String: Any] = [:]
        if includeLessons {
            parameters["includeLessons"] = "true"
        }

        do {
            let response: CEFRProgressResponse = try await apiClient.get(
                "\(APIEndpoint.roadmaps)/\(roadmapId)/cefr-progress",
                parameters: parameters,
                requiresAuth: false
            )

            NSLog("✅ Fetched CEFR progress for \(response.data.count) levels")
            os_log("✅ Fetched CEFR progress for %{public}d levels", log: logger, type: .info, response.data.count)

            return response.data
        } catch {
            NSLog("❌ Failed to fetch CEFR progress: \(error.localizedDescription)")
            os_log("❌ Failed to fetch CEFR progress: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    // MARK: - Curriculum Groups

    /// Fetch all curriculum groups for a roadmap
    /// GET /api/roadmaps/:roadmapId/groups
    /// - Parameters:
    ///   - roadmapId: Roadmap UUID
    ///   - cefrLevel: Filter by CEFR level (optional)
    ///   - includeLessons: Include lessons for each group (default: false)
    func fetchCurriculumGroups(
        roadmapId: String,
        cefrLevel: CEFRLevel? = nil,
        includeLessons: Bool = false
    ) async throws -> [CurriculumGroup] {
        NSLog("📚 Fetching curriculum groups for roadmap: \(roadmapId)...")
        os_log("📚 Fetching curriculum groups...", log: logger, type: .info)

        var parameters: [String: Any] = [:]
        if let level = cefrLevel {
            parameters["cefrLevel"] = level.rawValue
        }
        if includeLessons {
            parameters["includeLessons"] = "true"
        }

        do {
            let response: CurriculumGroupsResponse = try await apiClient.get(
                "\(APIEndpoint.roadmaps)/\(roadmapId)/groups",
                parameters: parameters,
                requiresAuth: false
            )

            NSLog("✅ Fetched \(response.data.count) curriculum groups")
            os_log("✅ Fetched %{public}d curriculum groups", log: logger, type: .info, response.data.count)

            return response.data
        } catch {
            NSLog("❌ Failed to fetch curriculum groups: \(error.localizedDescription)")
            os_log("❌ Failed to fetch curriculum groups: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    /// Fetch specific curriculum group
    /// GET /api/roadmaps/:roadmapId/groups/:groupId
    /// - Parameters:
    ///   - roadmapId: Roadmap UUID
    ///   - groupId: Curriculum group UUID
    ///   - includeLessons: Include lessons (default: true)
    func fetchCurriculumGroup(
        roadmapId: String,
        groupId: String,
        includeLessons: Bool = true
    ) async throws -> CurriculumGroup {
        NSLog("📚 Fetching curriculum group: \(groupId)...")
        os_log("📚 Fetching curriculum group...", log: logger, type: .info)

        var parameters: [String: Any] = [:]
        if includeLessons {
            parameters["includeLessons"] = "true"
        }

        do {
            let response: CurriculumGroupResponse = try await apiClient.get(
                "\(APIEndpoint.roadmaps)/\(roadmapId)/groups/\(groupId)",
                parameters: parameters,
                requiresAuth: false
            )

            NSLog("✅ Fetched curriculum group: \(response.data.name)")
            os_log("✅ Fetched curriculum group: %{public}@", log: logger, type: .info, response.data.name)

            return response.data
        } catch {
            NSLog("❌ Failed to fetch curriculum group: \(error.localizedDescription)")
            os_log("❌ Failed to fetch curriculum group: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    /// Fetch groups that fill Madrigal methodology gaps
    /// GET /api/roadmaps/:roadmapId/groups/madrigal-gaps
    /// - Parameter roadmapId: Roadmap UUID
    func fetchMadrigalGapGroups(roadmapId: String) async throws -> [CurriculumGroup] {
        NSLog("🔍 Fetching Madrigal gap groups for roadmap: \(roadmapId)...")
        os_log("🔍 Fetching Madrigal gap groups...", log: logger, type: .info)

        do {
            let response: CurriculumGroupsResponse = try await apiClient.get(
                "\(APIEndpoint.roadmaps)/\(roadmapId)/groups/madrigal-gaps",
                requiresAuth: false
            )

            NSLog("✅ Fetched \(response.data.count) Madrigal gap groups")
            os_log("✅ Fetched %{public}d Madrigal gap groups", log: logger, type: .info, response.data.count)

            return response.data
        } catch {
            NSLog("❌ Failed to fetch Madrigal gap groups: \(error.localizedDescription)")
            os_log("❌ Failed to fetch Madrigal gap groups: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    // MARK: - Regional Variants

    /// Fetch regional variants for a roadmap's language
    /// GET /api/roadmaps/:roadmapId/regional-variants
    /// - Parameter roadmapId: Roadmap UUID
    func fetchRegionalVariants(roadmapId: String) async throws -> [RegionalVariant] {
        NSLog("🌍 Fetching regional variants for roadmap: \(roadmapId)...")
        os_log("🌍 Fetching regional variants...", log: logger, type: .info)

        do {
            let response: RegionalVariantsResponse = try await apiClient.get(
                "\(APIEndpoint.roadmaps)/\(roadmapId)/regional-variants",
                requiresAuth: false
            )

            NSLog("✅ Fetched \(response.data.count) regional variants")
            os_log("✅ Fetched %{public}d regional variants", log: logger, type: .info, response.data.count)

            return response.data
        } catch {
            NSLog("❌ Failed to fetch regional variants: \(error.localizedDescription)")
            os_log("❌ Failed to fetch regional variants: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    // MARK: - Helper Methods

    /// Get default regional variant from list
    func getDefaultVariant(from variants: [RegionalVariant]) -> RegionalVariant? {
        variants.first { $0.isDefault }
    }

    /// Filter groups by CEFR level
    func filterGroups(_ groups: [CurriculumGroup], byLevel level: CEFRLevel) -> [CurriculumGroup] {
        groups.filter { group in
            group.cefrLevel == level || group.cefrLevelSecondary == level
        }
    }

    /// Sort groups by display order
    func sortGroupsByOrder(_ groups: [CurriculumGroup]) -> [CurriculumGroup] {
        groups.sorted { $0.displayOrder < $1.displayOrder }
    }

    /// Get groups by type
    func filterGroups(_ groups: [CurriculumGroup], byType type: GroupType) -> [CurriculumGroup] {
        groups.filter { $0.groupType == type }
    }

    /// Get Madrigal gap groups
    func filterMadrigalGapGroups(_ groups: [CurriculumGroup]) -> [CurriculumGroup] {
        groups.filter { $0.fillsMadrigalGap }
    }
}
