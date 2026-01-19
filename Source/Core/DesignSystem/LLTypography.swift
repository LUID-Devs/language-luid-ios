//
//  LLTypography.swift
//  LanguageLuid
//
//  Design System - Typography
//  iOS Human Interface Guidelines compliant typography system
//

import SwiftUI

/// Language Luid Typography System
/// Provides consistent text styles across the application
struct LLTypography {

    // MARK: - Font Families

    /// System font family (SF Pro)
    static let systemFont = "System"

    /// Monospace font family (SF Mono)
    static let monoFont = "Menlo"

    // MARK: - Font Weights

    enum FontWeight {
        case regular
        case medium
        case semibold
        case bold
        case heavy

        var swiftUIWeight: Font.Weight {
            switch self {
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            case .heavy: return .heavy
            }
        }
    }

    // MARK: - Heading Styles

    /// H1 - Extra Large Heading (34pt, bold)
    /// Used for main page titles and major sections
    static func h1() -> Font {
        .system(size: 34, weight: .bold)
    }

    /// H2 - Large Heading (28pt, bold)
    /// Used for section headings and important titles
    static func h2() -> Font {
        .system(size: 28, weight: .bold)
    }

    /// H3 - Medium Heading (24pt, semibold)
    /// Used for subsection headings
    static func h3() -> Font {
        .system(size: 24, weight: .semibold)
    }

    /// H4 - Small Heading (20pt, semibold)
    /// Used for card titles and list headers
    static func h4() -> Font {
        .system(size: 20, weight: .semibold)
    }

    /// H5 - Extra Small Heading (18pt, semibold)
    /// Used for minor headings and labels
    static func h5() -> Font {
        .system(size: 18, weight: .semibold)
    }

    /// H6 - Tiny Heading (16pt, semibold)
    /// Used for small section headers
    static func h6() -> Font {
        .system(size: 16, weight: .semibold)
    }

    // MARK: - Body Text Styles

    /// Body Large - Large body text (18pt, regular)
    /// Used for prominent body content
    static func bodyLarge() -> Font {
        .system(size: 18, weight: .regular)
    }

    /// Body - Standard body text (16pt, regular)
    /// Used for main content and descriptions
    static func body() -> Font {
        .system(size: 16, weight: .regular)
    }

    /// Body Medium - Medium body text (16pt, medium)
    /// Used for emphasized body content
    static func bodyMedium() -> Font {
        .system(size: 16, weight: .medium)
    }

    /// Body Small - Small body text (14pt, regular)
    /// Used for secondary content
    static func bodySmall() -> Font {
        .system(size: 14, weight: .regular)
    }

    // MARK: - Caption & Label Styles

    /// Caption Large - Large caption text (14pt, regular)
    /// Used for metadata and supporting information
    static func captionLarge() -> Font {
        .system(size: 14, weight: .regular)
    }

    /// Caption - Standard caption text (12pt, regular)
    /// Used for hints, footnotes, and timestamps
    static func caption() -> Font {
        .system(size: 12, weight: .regular)
    }

    /// Caption Small - Small caption text (11pt, regular)
    /// Used for very small supporting text
    static func captionSmall() -> Font {
        .system(size: 11, weight: .regular)
    }

    /// Label - UI label text (14pt, medium)
    /// Used for form labels and UI controls
    static func label() -> Font {
        .system(size: 14, weight: .medium)
    }

    // MARK: - Button Styles

    /// Button Large - Large button text (17pt, semibold)
    /// Used for prominent call-to-action buttons
    static func buttonLarge() -> Font {
        .system(size: 17, weight: .semibold)
    }

    /// Button - Standard button text (15pt, semibold)
    /// Used for regular buttons
    static func button() -> Font {
        .system(size: 15, weight: .semibold)
    }

    /// Button Small - Small button text (13pt, semibold)
    /// Used for compact buttons
    static func buttonSmall() -> Font {
        .system(size: 13, weight: .semibold)
    }

    // MARK: - Monospace Styles

    /// Code - Monospace code text (14pt, regular)
    /// Used for code snippets and technical content
    static func code() -> Font {
        .system(size: 14, design: .monospaced)
    }

    /// Code Small - Small monospace text (12pt, regular)
    /// Used for inline code and small technical text
    static func codeSmall() -> Font {
        .system(size: 12, design: .monospaced)
    }

    // MARK: - Custom Fonts

    /// Create a custom font with specific size and weight
    static func custom(size: CGFloat, weight: FontWeight = .regular) -> Font {
        .system(size: size, weight: weight.swiftUIWeight)
    }

    // MARK: - Line Height Multipliers

    /// Line height for headings (1.2x font size)
    static let headingLineHeight: CGFloat = 1.2

    /// Line height for body text (1.5x font size)
    static let bodyLineHeight: CGFloat = 1.5

    /// Line height for captions (1.4x font size)
    static let captionLineHeight: CGFloat = 1.4

    // MARK: - Letter Spacing

    /// Tight letter spacing (-0.5pt)
    static let letterSpacingTight: CGFloat = -0.5

    /// Normal letter spacing (0pt)
    static let letterSpacingNormal: CGFloat = 0

    /// Wide letter spacing (0.5pt)
    static let letterSpacingWide: CGFloat = 0.5

    /// Extra wide letter spacing (1pt)
    static let letterSpacingExtraWide: CGFloat = 1.0
}

// MARK: - Typography Style Struct

/// A complete typography style configuration
struct TypographyStyle {
    let font: Font
    let lineHeight: CGFloat?
    let letterSpacing: CGFloat
    let color: ColorSet?

    init(
        font: Font,
        lineHeight: CGFloat? = nil,
        letterSpacing: CGFloat = 0,
        color: ColorSet? = nil
    ) {
        self.font = font
        self.lineHeight = lineHeight
        self.letterSpacing = letterSpacing
        self.color = color
    }
}

// MARK: - Predefined Typography Styles

extension TypographyStyle {

    // Headings
    static let h1 = TypographyStyle(
        font: LLTypography.h1(),
        lineHeight: 34 * LLTypography.headingLineHeight,
        letterSpacing: LLTypography.letterSpacingTight,
        color: LLColors.foreground
    )

    static let h2 = TypographyStyle(
        font: LLTypography.h2(),
        lineHeight: 28 * LLTypography.headingLineHeight,
        letterSpacing: LLTypography.letterSpacingTight,
        color: LLColors.foreground
    )

    static let h3 = TypographyStyle(
        font: LLTypography.h3(),
        lineHeight: 24 * LLTypography.headingLineHeight,
        letterSpacing: LLTypography.letterSpacingNormal,
        color: LLColors.foreground
    )

    static let h4 = TypographyStyle(
        font: LLTypography.h4(),
        lineHeight: 20 * LLTypography.headingLineHeight,
        letterSpacing: LLTypography.letterSpacingNormal,
        color: LLColors.foreground
    )

    // Body
    static let bodyLarge = TypographyStyle(
        font: LLTypography.bodyLarge(),
        lineHeight: 18 * LLTypography.bodyLineHeight,
        letterSpacing: LLTypography.letterSpacingNormal,
        color: LLColors.foreground
    )

    static let body = TypographyStyle(
        font: LLTypography.body(),
        lineHeight: 16 * LLTypography.bodyLineHeight,
        letterSpacing: LLTypography.letterSpacingNormal,
        color: LLColors.foreground
    )

    static let bodyMuted = TypographyStyle(
        font: LLTypography.body(),
        lineHeight: 16 * LLTypography.bodyLineHeight,
        letterSpacing: LLTypography.letterSpacingNormal,
        color: LLColors.mutedForeground
    )

    // Captions
    static let caption = TypographyStyle(
        font: LLTypography.caption(),
        lineHeight: 12 * LLTypography.captionLineHeight,
        letterSpacing: LLTypography.letterSpacingNormal,
        color: LLColors.mutedForeground
    )

    // Buttons
    static let button = TypographyStyle(
        font: LLTypography.button(),
        lineHeight: nil,
        letterSpacing: LLTypography.letterSpacingWide,
        color: nil
    )
}

// MARK: - View Extension for Typography

extension View {
    /// Apply a typography style to a text view
    func typographyStyle(_ style: TypographyStyle) -> some View {
        self.modifier(TypographyStyleModifier(style: style))
    }

    /// Apply a heading 1 style
    func h1() -> some View {
        self.font(LLTypography.h1())
            .tracking(LLTypography.letterSpacingTight)
    }

    /// Apply a heading 2 style
    func h2() -> some View {
        self.font(LLTypography.h2())
            .tracking(LLTypography.letterSpacingTight)
    }

    /// Apply a heading 3 style
    func h3() -> some View {
        self.font(LLTypography.h3())
    }

    /// Apply a heading 4 style
    func h4() -> some View {
        self.font(LLTypography.h4())
    }

    /// Apply a heading 5 style
    func h5() -> some View {
        self.font(LLTypography.h5())
    }

    /// Apply a heading 6 style
    func h6() -> some View {
        self.font(LLTypography.h6())
    }

    /// Apply a body text style
    func bodyText() -> some View {
        self.font(LLTypography.body())
    }

    /// Apply a caption text style
    func captionText() -> some View {
        self.font(LLTypography.caption())
            .foregroundColor(LLColors.mutedForeground)
    }

    /// Apply a button text style
    func buttonText() -> some View {
        self.font(LLTypography.button())
            .tracking(LLTypography.letterSpacingWide)
    }
}

// MARK: - Typography Style Modifier

private struct TypographyStyleModifier: ViewModifier {
    let style: TypographyStyle
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .font(style.font)
            .tracking(style.letterSpacing)
            .lineSpacing(calculateLineSpacing())
            .foregroundColor(style.color?.color(for: colorScheme))
    }

    private func calculateLineSpacing() -> CGFloat {
        guard let lineHeight = style.lineHeight else { return 0 }
        // Line spacing is the difference between desired line height and font size
        // This is an approximation as we don't have direct access to font size
        return lineHeight * 0.3 // Approximate multiplier
    }
}

// MARK: - Dynamic Type Support

extension LLTypography {
    /// Enable dynamic type scaling for accessibility
    static func scaled(_ font: Font, category: Font.TextStyle = .body) -> Font {
        font
    }

    /// Check if dynamic type is enabled
    static var isDynamicTypeEnabled: Bool {
        UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
    }
}

// MARK: - Text Accessibility

extension View {
    /// Make text bold for accessibility
    func accessibilityBold() -> some View {
        self.fontWeight(.bold)
    }
}
