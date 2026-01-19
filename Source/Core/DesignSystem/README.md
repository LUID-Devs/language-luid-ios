# Language Luid iOS Design System

A comprehensive, production-ready design system for the Language Luid iOS app, inspired by and matching the language-luid-frontend web application.

## Overview

This design system provides a consistent, accessible, and beautiful user interface across the entire iOS application. It includes:

- **Color Palette**: Full light/dark mode support with OKLCH color space
- **Typography**: iOS HIG-compliant text styles
- **Spacing**: Consistent layout and sizing values
- **Components**: Reusable UI components

## File Structure

```
DesignSystem/
├── LLColors.swift           # Color palette and theming
├── LLTypography.swift       # Typography system
├── LLSpacing.swift          # Spacing and layout constants
└── Components/
    ├── LLButton.swift       # Button component
    ├── LLTextField.swift    # Text field component
    ├── LLCard.swift         # Card component
    ├── LLBadge.swift        # Badge component
    └── LLLoadingView.swift  # Loading indicators
```

## Quick Start

### Colors

```swift
import SwiftUI

struct MyView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            // Using adaptive colors
            Text("Hello")
                .foregroundColor(LLColors.foreground.adaptive)

            // Using colors with color scheme
            Text("World")
                .foregroundColor(LLColors.primary.color(for: colorScheme))
        }
        .background(LLColors.background.adaptive)
    }
}
```

#### Available Color Sets

**Primary Colors:**
- `LLColors.primary` / `LLColors.primaryForeground`
- `LLColors.secondary` / `LLColors.secondaryForeground`
- `LLColors.accent` / `LLColors.accentForeground`

**Background Colors:**
- `LLColors.background` / `LLColors.foreground`
- `LLColors.card` / `LLColors.cardForeground`
- `LLColors.muted` / `LLColors.mutedForeground`

**Semantic Colors:**
- `LLColors.destructive` / `LLColors.destructiveForeground`
- `LLColors.success` / `LLColors.successForeground`
- `LLColors.warning` / `LLColors.warningForeground`
- `LLColors.info` / `LLColors.infoForeground`

**Border & Input:**
- `LLColors.border`
- `LLColors.input`
- `LLColors.ring`

**Pronunciation Colors:**
- `LLColors.pronunciationExcellent` (90-100%)
- `LLColors.pronunciationGood` (70-89%)
- `LLColors.pronunciationFair` (50-69%)
- `LLColors.pronunciationPoor` (0-49%)

### Typography

```swift
VStack(alignment: .leading, spacing: LLSpacing.md) {
    // Heading styles
    Text("Main Title").h1()
    Text("Section Title").h2()
    Text("Subsection").h3()

    // Body text
    Text("Body content").bodyText()
    Text("Caption").captionText()

    // Button text
    Text("Button Text").buttonText()
}
```

#### Typography Styles

**Headings:**
- `LLTypography.h1()` - 34pt, bold
- `LLTypography.h2()` - 28pt, bold
- `LLTypography.h3()` - 24pt, semibold
- `LLTypography.h4()` - 20pt, semibold
- `LLTypography.h5()` - 18pt, semibold
- `LLTypography.h6()` - 16pt, semibold

**Body Text:**
- `LLTypography.bodyLarge()` - 18pt
- `LLTypography.body()` - 16pt
- `LLTypography.bodyMedium()` - 16pt, medium
- `LLTypography.bodySmall()` - 14pt

**Captions:**
- `LLTypography.captionLarge()` - 14pt
- `LLTypography.caption()` - 12pt
- `LLTypography.captionSmall()` - 11pt

**Buttons:**
- `LLTypography.buttonLarge()` - 17pt, semibold
- `LLTypography.button()` - 15pt, semibold
- `LLTypography.buttonSmall()` - 13pt, semibold

### Spacing

```swift
VStack(spacing: LLSpacing.md) {
    // Using spacing constants
    Text("Item 1")
    Text("Item 2")
}
.padding(LLSpacing.paddingMD)

// Screen padding
VStack {
    Text("Content")
}
.screenPadding()

// Card padding
VStack {
    Text("Card Content")
}
.cardPadding()
```

#### Spacing Scale

- `LLSpacing.xs` - 4pt
- `LLSpacing.sm` - 8pt
- `LLSpacing.md` - 16pt
- `LLSpacing.lg` - 24pt
- `LLSpacing.xl` - 32pt
- `LLSpacing.xxl` - 48pt
- `LLSpacing.xxxl` - 64pt

#### Corner Radius

- `LLSpacing.radiusXS` - 2pt
- `LLSpacing.radiusSM` - 6pt
- `LLSpacing.radiusMD` - 8pt
- `LLSpacing.radiusLG` - 10pt
- `LLSpacing.radiusXL` - 14pt
- `LLSpacing.radiusXXL` - 20pt
- `LLSpacing.radiusFull` - Circular

## Components

### LLButton

```swift
// Basic button
LLButton("Click Me", style: .primary) {
    print("Button tapped")
}

// With icon
LLButton("Save", icon: Image(systemName: "checkmark"), style: .success) {
    save()
}

// Loading state
LLButton("Loading...", isLoading: true) { }

// Disabled
LLButton("Disabled", isDisabled: true) { }

// Icon only
LLButton(icon: Image(systemName: "gear"), size: .icon) {
    openSettings()
}

// Sizes
LLButton("Small", size: .sm) { }
LLButton("Medium", size: .md) { }
LLButton("Large", size: .lg) { }

// Full width
LLButton("Full Width", fullWidth: true) { }
```

#### Button Styles

- `.primary` - Main call-to-action
- `.secondary` - Secondary actions
- `.outline` - Outlined style
- `.ghost` - Minimal style
- `.destructive` - Dangerous actions
- `.success` - Positive actions
- `.warning` - Caution actions
- `.link` - Link style

### LLTextField

```swift
// Standard text field
@State private var name = ""
LLTextField("Enter your name", text: $name, label: "Name")

// Email field
@State private var email = ""
LLTextField(
    "Enter your email",
    text: $email,
    label: "Email",
    type: .email,
    leadingIcon: Image(systemName: "envelope")
)

// Password field
@State private var password = ""
LLTextField(
    "Enter password",
    text: $password,
    label: "Password",
    type: .password
)

// With validation
LLTextField(
    "Enter email",
    text: $email,
    label: "Email",
    type: .email,
    errorMessage: "Invalid email address"
)

// With success
LLTextField(
    "Enter email",
    text: $email,
    label: "Email",
    type: .email,
    successMessage: "Email is valid"
)

// With character limit
LLTextField(
    "Username",
    text: $username,
    label: "Username",
    helperText: "3-20 characters",
    maxLength: 20
)

// Password strength indicator
VStack {
    LLTextField(
        "Create password",
        text: $password,
        label: "Password",
        type: .secure
    )
    LLPasswordStrengthIndicator(password: password)
}
```

#### Text Field Types

- `.standard` - Standard text input
- `.email` - Email keyboard
- `.password` - Secure entry with toggle
- `.secure` - Secure entry for new password
- `.numeric` - Number pad
- `.phone` - Phone pad
- `.url` - URL keyboard

### LLCard

```swift
// Standard card
LLCard.standard(
    title: "Card Title",
    description: "Card description"
) {
    Text("Card content")
}

// Simple card
LLCard.simple {
    VStack {
        Text("Simple card content")
    }
}

// Interactive card
LLCard(style: .standard, onTap: {
    print("Card tapped")
}) {
    Text("Tap me!")
}

// Language card (specialized)
LLLanguageCard(
    languageName: "Spanish",
    flagEmoji: "🇪🇸",
    lessonsCount: 24,
    progress: 0.65
) {
    openLanguage()
}
```

#### Card Styles

- `.standard` - Default card with subtle shadow
- `.elevated` - Elevated card with larger shadow
- `.outlined` - Card with border
- `.filled` - Card with muted background

#### Card Padding

- `.none` - No padding
- `.sm` - Small padding (12pt)
- `.md` - Medium padding (24pt)
- `.lg` - Large padding (32pt)

### LLBadge

```swift
// Text badge
LLBadge("New", variant: .success)

// With icon
LLBadge("Premium", icon: Image(systemName: "star.fill"), variant: .warning)

// Dot indicator
LLBadge(variant: .success, size: .sm)

// Sizes
LLBadge("Small", size: .sm)
LLBadge("Medium", size: .md)
LLBadge("Large", size: .lg)

// CEFR level badge
LLBadge.cefrLevel("B2")

// Status badge
LLBadge.status("Active", isActive: true)

// Notification badge
ZStack(alignment: .topTrailing) {
    Image(systemName: "bell.fill")
    LLNotificationBadge(count: 5)
        .offset(x: 8, y: -8)
}

// Achievement badge
LLAchievementBadge(
    title: "First Lesson",
    icon: Image(systemName: "star.fill"),
    isUnlocked: true
)
```

#### Badge Variants

- `.default` - Default muted style
- `.secondary` - Secondary color
- `.success` - Green (positive)
- `.warning` - Orange (caution)
- `.error` - Red (danger)
- `.info` - Blue (informational)
- `.outline` - Outlined style

### LLLoadingView

```swift
// Spinner
LLSpinner(size: .md)

// Loading overlay
LLLoadingOverlay(message: "Loading...")

// Progress bar
LLProgressBar(progress: 0.65, showPercentage: true)

// Circular progress
LLCircularProgress(progress: 0.75, size: 60)

// Skeleton loading
LLSkeleton(width: 200, height: 16)
LLSkeletonCard()
LLSkeletonList(count: 5)

// Empty state
LLEmptyState(
    icon: Image(systemName: "tray"),
    title: "No items",
    description: "Start by adding your first item",
    actionTitle: "Add Item",
    action: { addItem() }
)

// Loading state pattern
@State private var loadingState: LLLoadingState<[Language]> = .loading

var body: some View {
    ScrollView {
        VStack {
            content
        }
    }
    .loadingState(
        loadingState,
        content: { languages in
            ForEach(languages) { language in
                LanguageRow(language: language)
            }
        },
        placeholder: {
            LLSkeletonList(count: 5)
        },
        error: { error in
            LLEmptyState(
                icon: Image(systemName: "exclamationmark.triangle"),
                title: "Error",
                description: error.localizedDescription
            )
        }
    )
}
```

## Design Principles

### 1. Consistency
All components use the same color palette, spacing, and typography system to ensure visual consistency.

### 2. Accessibility
- Full light/dark mode support
- Minimum touch target sizes (44pt)
- Clear focus states
- Semantic color usage
- Dynamic Type support

### 3. Performance
- Lightweight components
- Efficient animations
- Optimized rendering
- Minimal re-renders

### 4. Flexibility
- Customizable variants
- Composable components
- Extensive modifier support
- Easy theming

## Best Practices

### Using Colors

```swift
// ✅ Good - Use adaptive colors
Text("Hello")
    .foregroundColor(LLColors.foreground.adaptive)

// ❌ Avoid - Don't use hardcoded colors
Text("Hello")
    .foregroundColor(.black)
```

### Using Spacing

```swift
// ✅ Good - Use spacing constants
VStack(spacing: LLSpacing.md) { }

// ❌ Avoid - Don't use magic numbers
VStack(spacing: 16) { }
```

### Using Typography

```swift
// ✅ Good - Use typography helpers
Text("Title").h2()

// ❌ Avoid - Don't specify fonts manually
Text("Title").font(.system(size: 28, weight: .bold))
```

### Component Composition

```swift
// ✅ Good - Compose components
LLCard.standard(title: "Title") {
    VStack(spacing: LLSpacing.md) {
        LLBadge("New", variant: .success)
        Text("Content").bodyText()
        LLButton("Action") { }
    }
}

// ✅ Also good - Build custom components with design system
struct CustomComponent: View {
    var body: some View {
        VStack(spacing: LLSpacing.md) {
            // Use design system components and values
        }
    }
}
```

## Migration from Storyboards/UIKit

If migrating from UIKit/Storyboards:

1. Replace `UIColor` with `LLColors`
2. Replace `UIFont` with `LLTypography`
3. Replace magic numbers with `LLSpacing`
4. Use SwiftUI components instead of UIKit views

## Contributing

When adding new components or modifying existing ones:

1. Follow existing patterns and naming conventions
2. Support both light and dark mode
3. Include accessibility features
4. Add comprehensive previews
5. Document usage with examples
6. Test on multiple device sizes

## Support

For questions or issues with the design system, contact the development team or create an issue in the project repository.

---

**Version:** 1.0.0
**Last Updated:** January 19, 2026
**Maintained by:** Language Luid Development Team
