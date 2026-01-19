//
//  LLSpacing.swift
//  LanguageLuid
//
//  Design System - Spacing & Layout Constants
//  Provides consistent spacing, padding, and sizing values
//

import SwiftUI

/// Language Luid Spacing System
/// Defines consistent spacing, padding, corner radius, and sizing values
struct LLSpacing {

    // MARK: - Base Spacing Scale

    /// Extra small spacing (4pt)
    static let xs: CGFloat = 4

    /// Small spacing (8pt)
    static let sm: CGFloat = 8

    /// Medium spacing (16pt)
    static let md: CGFloat = 16

    /// Large spacing (24pt)
    static let lg: CGFloat = 24

    /// Extra large spacing (32pt)
    static let xl: CGFloat = 32

    /// Extra extra large spacing (48pt)
    static let xxl: CGFloat = 48

    /// Extra extra extra large spacing (64pt)
    static let xxxl: CGFloat = 64

    // MARK: - Padding Values

    /// Padding for extra small elements
    static let paddingXS = EdgeInsets(top: xs, leading: xs, bottom: xs, trailing: xs)

    /// Padding for small elements
    static let paddingSM = EdgeInsets(top: sm, leading: sm, bottom: sm, trailing: sm)

    /// Padding for medium elements
    static let paddingMD = EdgeInsets(top: md, leading: md, bottom: md, trailing: md)

    /// Padding for large elements
    static let paddingLG = EdgeInsets(top: lg, leading: lg, bottom: lg, trailing: lg)

    /// Padding for extra large elements
    static let paddingXL = EdgeInsets(top: xl, leading: xl, bottom: xl, trailing: xl)

    /// Card padding (24pt) - matches web app card padding
    static let cardPadding = EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24)

    /// Card header padding (24pt top/sides, 6pt bottom for spacing)
    static let cardHeaderPadding = EdgeInsets(top: 24, leading: 24, bottom: 6, trailing: 24)

    /// Card content padding (0pt top, 24pt sides/bottom)
    static let cardContentPadding = EdgeInsets(top: 0, leading: 24, bottom: 24, trailing: 24)

    // MARK: - Corner Radius Values

    /// Base border radius value (10pt) - matches web --radius: 0.625rem
    private static let baseRadius: CGFloat = 10

    /// Extra small corner radius (2pt)
    static let radiusXS: CGFloat = 2

    /// Small corner radius (6pt) - calc(var(--radius) - 4px)
    static let radiusSM: CGFloat = baseRadius - 4

    /// Medium corner radius (8pt) - calc(var(--radius) - 2px)
    static let radiusMD: CGFloat = baseRadius - 2

    /// Large corner radius (10pt) - var(--radius)
    static let radiusLG: CGFloat = baseRadius

    /// Extra large corner radius (14pt) - calc(var(--radius) + 4px)
    static let radiusXL: CGFloat = baseRadius + 4

    /// Extra extra large corner radius (20pt)
    static let radiusXXL: CGFloat = 20

    /// Full corner radius (for circular elements)
    static let radiusFull: CGFloat = 9999

    // MARK: - Icon Sizes

    /// Extra small icon size (12pt)
    static let iconXS: CGFloat = 12

    /// Small icon size (16pt)
    static let iconSM: CGFloat = 16

    /// Medium icon size (20pt)
    static let iconMD: CGFloat = 20

    /// Large icon size (24pt)
    static let iconLG: CGFloat = 24

    /// Extra large icon size (32pt)
    static let iconXL: CGFloat = 32

    /// Extra extra large icon size (48pt)
    static let iconXXL: CGFloat = 48

    // MARK: - Button Sizes

    /// Small button height (36pt)
    static let buttonHeightSM: CGFloat = 36

    /// Medium button height (40pt) - matches web h-10
    static let buttonHeightMD: CGFloat = 40

    /// Large button height (44pt) - matches web h-11
    static let buttonHeightLG: CGFloat = 44

    /// Extra large button height (48pt)
    static let buttonHeightXL: CGFloat = 48

    /// Icon button size (40pt)
    static let buttonIconSize: CGFloat = 40

    // MARK: - Input Field Sizes

    /// Input field height (40pt) - matches web h-10
    static let inputHeight: CGFloat = 40

    /// Large input field height (48pt)
    static let inputHeightLG: CGFloat = 48

    /// Input field horizontal padding (12pt)
    static let inputPaddingHorizontal: CGFloat = 12

    /// Input field vertical padding (8pt)
    static let inputPaddingVertical: CGFloat = 8

    // MARK: - Badge Sizes

    /// Small badge height (20pt)
    static let badgeHeightSM: CGFloat = 20

    /// Medium badge height (24pt)
    static let badgeHeightMD: CGFloat = 28

    /// Large badge height (32pt)
    static let badgeHeightLG: CGFloat = 32

    /// Badge horizontal padding (10pt)
    static let badgePaddingHorizontal: CGFloat = 10

    /// Small badge horizontal padding (8pt)
    static let badgePaddingHorizontalSM: CGFloat = 8

    // MARK: - Avatar Sizes

    /// Extra small avatar size (24pt)
    static let avatarXS: CGFloat = 24

    /// Small avatar size (32pt)
    static let avatarSM: CGFloat = 32

    /// Medium avatar size (40pt)
    static let avatarMD: CGFloat = 40

    /// Large avatar size (48pt)
    static let avatarLG: CGFloat = 48

    /// Extra large avatar size (64pt)
    static let avatarXL: CGFloat = 64

    /// Extra extra large avatar size (96pt)
    static let avatarXXL: CGFloat = 96

    // MARK: - Divider & Border Widths

    /// Thin border width (0.5pt)
    static let borderThin: CGFloat = 0.5

    /// Standard border width (1pt)
    static let borderStandard: CGFloat = 1

    /// Thick border width (2pt)
    static let borderThick: CGFloat = 2

    /// Divider height (1pt)
    static let dividerHeight: CGFloat = 1

    // MARK: - Shadow Values

    /// Small shadow
    static let shadowSM: CGFloat = 2
    static let shadowSMRadius: CGFloat = 4

    /// Medium shadow
    static let shadowMD: CGFloat = 4
    static let shadowMDRadius: CGFloat = 8

    /// Large shadow
    static let shadowLG: CGFloat = 8
    static let shadowLGRadius: CGFloat = 16

    /// Extra large shadow
    static let shadowXL: CGFloat = 12
    static let shadowXLRadius: CGFloat = 24

    // MARK: - Layout Constants

    /// Screen horizontal padding (16pt)
    static let screenPaddingHorizontal: CGFloat = 16

    /// Screen vertical padding (16pt)
    static let screenPaddingVertical: CGFloat = 16

    /// Section spacing (24pt)
    static let sectionSpacing: CGFloat = 24

    /// List item spacing (12pt)
    static let listItemSpacing: CGFloat = 12

    /// Grid spacing (16pt)
    static let gridSpacing: CGFloat = 16

    /// Safe area top inset (typically status bar height)
    static var safeAreaTop: CGFloat {
        UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
    }

    /// Safe area bottom inset (typically home indicator height)
    static var safeAreaBottom: CGFloat {
        UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
    }

    // MARK: - Navigation & Tab Bar

    /// Navigation bar height (44pt)
    static let navBarHeight: CGFloat = 44

    /// Large navigation bar height (96pt)
    static let navBarHeightLarge: CGFloat = 96

    /// Tab bar height (49pt)
    static let tabBarHeight: CGFloat = 49

    /// Tab bar icon size (28pt)
    static let tabBarIconSize: CGFloat = 28

    // MARK: - Progress & Slider

    /// Progress bar height (8pt)
    static let progressBarHeight: CGFloat = 8

    /// Thin progress bar height (4pt)
    static let progressBarHeightThin: CGFloat = 4

    /// Slider track height (4pt)
    static let sliderTrackHeight: CGFloat = 4

    /// Slider thumb size (28pt)
    static let sliderThumbSize: CGFloat = 28

    // MARK: - Minimum Touch Target

    /// Minimum touch target size for accessibility (44pt)
    static let minTouchTarget: CGFloat = 44

    // MARK: - Z-Index / Layer Priority

    /// Dropdown/popover z-index
    static let zIndexPopover: Double = 100

    /// Modal/sheet z-index
    static let zIndexModal: Double = 200

    /// Toast/notification z-index
    static let zIndexToast: Double = 300

    /// Tooltip z-index
    static let zIndexTooltip: Double = 400
}

// MARK: - Edge Insets Extensions

extension EdgeInsets {
    /// Create symmetric edge insets
    static func symmetric(horizontal: CGFloat = 0, vertical: CGFloat = 0) -> EdgeInsets {
        EdgeInsets(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal)
    }

    /// Create uniform edge insets
    static func all(_ value: CGFloat) -> EdgeInsets {
        EdgeInsets(top: value, leading: value, bottom: value, trailing: value)
    }

    /// Create edge insets with only horizontal padding
    static func horizontal(_ value: CGFloat) -> EdgeInsets {
        EdgeInsets(top: 0, leading: value, bottom: 0, trailing: value)
    }

    /// Create edge insets with only vertical padding
    static func vertical(_ value: CGFloat) -> EdgeInsets {
        EdgeInsets(top: value, leading: 0, bottom: value, trailing: 0)
    }
}

// MARK: - View Extensions for Spacing

extension View {
    /// Apply consistent screen padding
    func screenPadding() -> some View {
        self.padding(.horizontal, LLSpacing.screenPaddingHorizontal)
            .padding(.vertical, LLSpacing.screenPaddingVertical)
    }

    /// Apply card padding
    func cardPadding() -> some View {
        self.padding(LLSpacing.cardPadding)
    }

    /// Apply consistent spacing between elements
    func itemSpacing(_ spacing: CGFloat = LLSpacing.md) -> some View {
        self.padding(.bottom, spacing)
    }

    /// Apply minimum touch target size
    func minTouchTarget() -> some View {
        self.frame(minWidth: LLSpacing.minTouchTarget, minHeight: LLSpacing.minTouchTarget)
    }
}

// MARK: - Spacing Presets

extension LLSpacing {
    /// Vertical spacing values for VStack
    struct Vertical {
        static let xs = LLSpacing.xs
        static let sm = LLSpacing.sm
        static let md = LLSpacing.md
        static let lg = LLSpacing.lg
        static let xl = LLSpacing.xl
    }

    /// Horizontal spacing values for HStack
    struct Horizontal {
        static let xs = LLSpacing.xs
        static let sm = LLSpacing.sm
        static let md = LLSpacing.md
        static let lg = LLSpacing.lg
        static let xl = LLSpacing.xl
    }
}
