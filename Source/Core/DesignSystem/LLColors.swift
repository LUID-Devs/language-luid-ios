//
//  LLColors.swift
//  LanguageLuid
//
//  Design System - Color Palette
//  Matches the language-luid-frontend web app color scheme
//

import SwiftUI

/// Language Luid Color System
/// Provides a comprehensive color palette with full light/dark mode support
/// Based on OKLCH color space for perceptually uniform colors
struct LLColors {

    // MARK: - Primary Colors

    /// Primary brand color - used for main actions and key UI elements
    static let primary = ColorSet(
        light: Color(oklch: OKLCH(l: 0.205, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.922, c: 0, h: 0))
    )

    static let primaryForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.985, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.205, c: 0, h: 0))
    )

    // MARK: - Secondary Colors

    /// Secondary color - for less prominent UI elements
    static let secondary = ColorSet(
        light: Color(oklch: OKLCH(l: 0.97, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.269, c: 0, h: 0))
    )

    static let secondaryForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.205, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.985, c: 0, h: 0))
    )

    // MARK: - Accent Colors

    /// Accent color - for highlights and emphasis
    static let accent = ColorSet(
        light: Color(oklch: OKLCH(l: 0.97, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.269, c: 0, h: 0))
    )

    static let accentForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.205, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.985, c: 0, h: 0))
    )

    // MARK: - Background Colors

    /// Main background color
    static let background = ColorSet(
        light: Color(oklch: OKLCH(l: 1, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.145, c: 0, h: 0))
    )

    /// Foreground text color
    static let foreground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.145, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.985, c: 0, h: 0))
    )

    /// Card background color
    static let card = ColorSet(
        light: Color(oklch: OKLCH(l: 1, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.205, c: 0, h: 0))
    )

    static let cardForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.145, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.985, c: 0, h: 0))
    )

    /// Muted background for disabled or less important elements
    static let muted = ColorSet(
        light: Color(oklch: OKLCH(l: 0.97, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.269, c: 0, h: 0))
    )

    static let mutedForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.556, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.708, c: 0, h: 0))
    )

    /// Popover background color
    static let popover = ColorSet(
        light: Color(oklch: OKLCH(l: 1, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.205, c: 0, h: 0))
    )

    static let popoverForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.145, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.985, c: 0, h: 0))
    )

    // MARK: - Semantic Colors

    /// Destructive/Error color - for dangerous actions and errors
    static let destructive = ColorSet(
        light: Color(oklch: OKLCH(l: 0.145, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.9, c: 0, h: 0))
    )

    static let destructiveForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.985, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.205, c: 0, h: 0))
    )

    /// Success color - for positive feedback and completed states
    static let success = ColorSet(
        light: Color(oklch: OKLCH(l: 0.24, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.82, c: 0, h: 0))
    )

    static let successForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.985, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.205, c: 0, h: 0))
    )

    /// Warning color - for caution and attention-needed states
    static let warning = ColorSet(
        light: Color(oklch: OKLCH(l: 0.32, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.7, c: 0, h: 0))
    )

    static let warningForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.985, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.205, c: 0, h: 0))
    )

    /// Info color - for informational messages
    static let info = ColorSet(
        light: Color(oklch: OKLCH(l: 0.4, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.6, c: 0, h: 0))
    )

    static let infoForeground = ColorSet(
        light: Color(oklch: OKLCH(l: 0.985, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.205, c: 0, h: 0))
    )

    // MARK: - Border & Input Colors

    /// Border color for UI elements
    static let border = ColorSet(
        light: Color(oklch: OKLCH(l: 0.922, c: 0, h: 0)),
        dark: Color(white: 1.0, opacity: 0.1)
    )

    /// Input field border color
    static let input = ColorSet(
        light: Color(oklch: OKLCH(l: 0.922, c: 0, h: 0)),
        dark: Color(white: 1.0, opacity: 0.15)
    )

    /// Focus ring color
    static let ring = ColorSet(
        light: Color(oklch: OKLCH(l: 0.708, c: 0, h: 0)),
        dark: Color(oklch: OKLCH(l: 0.556, c: 0, h: 0))
    )

    // MARK: - Pronunciation Score Colors

    /// Color for excellent pronunciation scores (90-100%)
    static let pronunciationExcellent = Color(white: 0.15)

    /// Color for good pronunciation scores (70-89%)
    static let pronunciationGood = Color(white: 0.25)

    /// Color for fair pronunciation scores (50-69%)
    static let pronunciationFair = Color(white: 0.35)

    /// Color for poor pronunciation scores (0-49%)
    static let pronunciationPoor = Color(white: 0.45)
}

// MARK: - Color Set Helper

/// Represents a color that adapts to light and dark mode
struct ColorSet {
    let light: Color
    let dark: Color

    /// Returns the appropriate color for the current color scheme
    func color(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? dark : light
    }

    /// Returns a dynamic color that automatically adapts to color scheme
    var adaptive: Color {
        Color(uiColor: UIColor { traitCollection in
            UIColor(traitCollection.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

// MARK: - OKLCH Color Space

/// OKLCH color representation for perceptually uniform colors
struct OKLCH {
    let l: Double // Lightness (0-1)
    let c: Double // Chroma (0-0.4 typically)
    let h: Double // Hue (0-360)

    init(l: Double, c: Double, h: Double) {
        self.l = l
        self.c = c
        self.h = h
    }
}

// MARK: - Color Extensions

extension Color {
    /// Initialize a Color from OKLCH values
    /// Converts OKLCH to RGB using Lab color space
    init(oklch: OKLCH) {
        // Convert OKLCH to Lab
        let a = oklch.c * cos(oklch.h * .pi / 180)
        let b = oklch.c * sin(oklch.h * .pi / 180)

        // Convert Lab to XYZ
        let fy = (oklch.l + 0.16) / 1.16
        let fx = a / 500 + fy
        let fz = fy - b / 200

        let xr = fx > 0.206897 ? pow(fx, 3) : (fx - 0.137931) / 7.787
        let yr = fy > 0.206897 ? pow(fy, 3) : (fy - 0.137931) / 7.787
        let zr = fz > 0.206897 ? pow(fz, 3) : (fz - 0.137931) / 7.787

        let x = xr * 0.95047
        let y = yr * 1.0
        let z = zr * 1.08883

        // Convert XYZ to RGB
        var r = x * 3.2406 + y * -1.5372 + z * -0.4986
        var g = x * -0.9689 + y * 1.8758 + z * 0.0415
        var bl = x * 0.0557 + y * -0.2040 + z * 1.0570

        // Apply gamma correction
        r = r > 0.0031308 ? 1.055 * pow(r, 1/2.4) - 0.055 : 12.92 * r
        g = g > 0.0031308 ? 1.055 * pow(g, 1/2.4) - 0.055 : 12.92 * g
        bl = bl > 0.0031308 ? 1.055 * pow(bl, 1/2.4) - 0.055 : 12.92 * bl

        // Clamp values
        r = max(0, min(1, r))
        g = max(0, min(1, g))
        bl = max(0, min(1, bl))

        self.init(red: r, green: g, blue: bl)
    }

    /// Returns the pronunciation score color based on percentage
    static func pronunciationColor(for score: Double) -> Color {
        switch score {
        case 90...100:
            return LLColors.pronunciationExcellent
        case 70..<90:
            return LLColors.pronunciationGood
        case 50..<70:
            return LLColors.pronunciationFair
        default:
            return LLColors.pronunciationPoor
        }
    }
}

// MARK: - SwiftUI Environment Extensions

extension EnvironmentValues {
    /// Access the design system colors easily in SwiftUI views
    var llColors: LLColors.Type {
        LLColors.self
    }
}

// MARK: - View Extensions for Color Scheme

extension View {
    /// Apply a color that adapts to the color scheme
    func foregroundColor(_ colorSet: ColorSet) -> some View {
        self.modifier(AdaptiveColorModifier(colorSet: colorSet, isBackground: false))
    }

    /// Apply a background color that adapts to the color scheme
    func backgroundColor(_ colorSet: ColorSet) -> some View {
        self.modifier(AdaptiveColorModifier(colorSet: colorSet, isBackground: true))
    }
}

private struct AdaptiveColorModifier: ViewModifier {
    let colorSet: ColorSet
    let isBackground: Bool
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        if isBackground {
            content.background(colorSet.color(for: colorScheme))
        } else {
            content.foregroundColor(colorSet.color(for: colorScheme))
        }
    }
}
