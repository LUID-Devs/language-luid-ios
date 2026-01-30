//
//  ThemePreference.swift
//  LanguageLuid
//
//  Theme preference management for app-wide appearance
//  Supports system, light, and dark modes with persistence
//

import SwiftUI

/// User's preferred app appearance theme
enum ThemePreference: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    /// Display name for UI
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    /// SF Symbol icon for each theme
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    /// Convert preference to SwiftUI ColorScheme
    /// Returns nil for system (follows device appearance)
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil  // Let system decide
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// Detailed description for UI
    var description: String {
        switch self {
        case .system:
            return "Automatically adjusts to match your device's appearance settings"
        case .light:
            return "Always use light appearance"
        case .dark:
            return "Always use dark appearance"
        }
    }
}

// MARK: - Storage Key

extension String {
    /// UserDefaults key for theme preference
    static let themePreferenceKey = "com.luid.languageluid.themePreference"
}
