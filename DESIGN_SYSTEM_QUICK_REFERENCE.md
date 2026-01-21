# Design System Quick Reference
## Language Luid iOS

A developer-friendly guide to using the Language Luid design system components.

---

## Color Usage

### Primary Colors
```swift
// Foreground (text, icons)
LLColors.foreground.color(for: colorScheme)
LLColors.mutedForeground.color(for: colorScheme)

// Background
LLColors.background.color(for: colorScheme)
LLColors.card.color(for: colorScheme)

// Brand
LLColors.primary.color(for: colorScheme)
LLColors.secondary.color(for: colorScheme)
```

### Semantic Colors
```swift
// Success (green)
LLColors.success.color(for: colorScheme)

// Error (red)
LLColors.destructive.color(for: colorScheme)

// Warning (orange/yellow)
LLColors.warning.color(for: colorScheme)

// Info (blue)
LLColors.info.color(for: colorScheme)
```

---

## Typography

### Headings
```swift
Text("Main Title")
    .font(LLTypography.h1())  // 34pt, bold

Text("Section Title")
    .font(LLTypography.h2())  // 28pt, bold

Text("Subsection")
    .font(LLTypography.h3())  // 24pt, semibold

Text("Card Title")
    .font(LLTypography.h4())  // 20pt, semibold
```

### Body Text
```swift
Text("Regular text")
    .font(LLTypography.body())  // 16pt

Text("Small text")
    .font(LLTypography.bodySmall())  // 14pt

Text("Caption")
    .font(LLTypography.caption())  // 12pt
```

### Shorthand Modifiers
```swift
Text("Heading 1").h1()
Text("Heading 2").h2()
Text("Body").bodyText()
Text("Caption").captionText()
```

---

## Spacing

### Basic Spacing
```swift
.padding(LLSpacing.xs)   // 4pt
.padding(LLSpacing.sm)   // 8pt
.padding(LLSpacing.md)   // 16pt
.padding(LLSpacing.lg)   // 24pt
.padding(LLSpacing.xl)   // 32pt
.padding(LLSpacing.xxl)  // 48pt
.padding(LLSpacing.xxxl) // 64pt
```

### Screen Padding
```swift
VStack {
    // Content
}
.screenPadding()  // 16pt horizontal + vertical
```

### Corner Radius
```swift
RoundedRectangle(cornerRadius: LLSpacing.radiusSM)  // 6pt
RoundedRectangle(cornerRadius: LLSpacing.radiusMD)  // 8pt
RoundedRectangle(cornerRadius: LLSpacing.radiusLG)  // 10pt
RoundedRectangle(cornerRadius: LLSpacing.radiusXL)  // 14pt
```

---

## Buttons

### Basic Usage
```swift
LLButton("Click Me", style: .primary) {
    // Action
}
```

### Button Styles
```swift
LLButton("Primary", style: .primary) { }
LLButton("Secondary", style: .secondary) { }
LLButton("Outline", style: .outline) { }
LLButton("Ghost", style: .ghost) { }
LLButton("Destructive", style: .destructive) { }
```

### Button Sizes
```swift
LLButton("Small", size: .sm) { }
LLButton("Medium", size: .md) { }  // Default
LLButton("Large", size: .lg) { }
```

### With Icons
```swift
LLButton("Save", icon: Image(systemName: "checkmark")) { }

// Icon only
LLButton(icon: Image(systemName: "gear")) { }
```

### States
```swift
LLButton("Loading", isLoading: true) { }
LLButton("Disabled", isDisabled: true) { }
LLButton("Full Width", fullWidth: true) { }
```

---

## Cards

### Basic Usage
```swift
LLCard(style: .standard) {
    Text("Card content")
}
```

### Card Styles
```swift
LLCard(style: .standard) { }   // Default with border
LLCard(style: .elevated) { }   // With shadow
LLCard(style: .outlined) { }   // Outlined border
LLCard(style: .filled) { }     // Filled background
```

### Card Padding
```swift
LLCard(padding: .none) { }
LLCard(padding: .sm) { }
LLCard(padding: .md) { }  // Default (24pt)
LLCard(padding: .lg) { }
```

### Interactive Cards
```swift
LLCard(onTap: {
    // Handle tap
}) {
    Text("Tappable card")
}
```

---

## Badges

### Basic Usage
```swift
LLBadge("Active", variant: .success)
```

### Badge Variants
```swift
LLBadge("Default", variant: .default)
LLBadge("Success", variant: .success)      // Green
LLBadge("Error", variant: .error)          // Red
LLBadge("Warning", variant: .warning)      // Orange
LLBadge("Info", variant: .info)            // Blue
LLBadge("Outline", variant: .outline)
```

### Badge Sizes
```swift
LLBadge("Small", size: .sm)
LLBadge("Medium", size: .md)  // Default
LLBadge("Large", size: .lg)
```

### With Icons
```swift
LLBadge("Pro", icon: Image(systemName: "crown.fill"))
```

---

## Empty States

### Basic Usage
```swift
LLEmptyState(
    icon: "tray.fill",
    title: "No Items",
    message: "Your items will appear here"
)
```

### With Action
```swift
LLEmptyState(
    icon: "dollarsign.circle.fill",
    title: "No Credits",
    message: "Purchase credits to continue",
    actionTitle: "Buy Credits",
    action: {
        // Navigate to purchase
    }
)
```

### Styles
```swift
LLEmptyState(..., style: .standard)  // Full featured
LLEmptyState(..., style: .minimal)   // Compact
LLEmptyState(..., style: .feature)   // Large, prominent
```

---

## Skeleton Loaders

### Basic Shapes
```swift
LLSkeletonLoader(shape: .rectangle(width: nil, height: 60))
LLSkeletonLoader(shape: .circle(diameter: 60))
LLSkeletonLoader(shape: .roundedRectangle(
    width: 200,
    height: 100,
    cornerRadius: 12
))
```

### Text Lines
```swift
LLSkeletonLoader(shape: .text(lines: 3, lineSpacing: 8))
```

### Pre-built Layouts
```swift
// For credit card
LLCreditCardSkeleton()

// For transaction row
LLTransactionRowSkeleton()
```

---

## Progress Indicators

### Linear Progress
```swift
LLLinearProgress(value: 0.65)
LLLinearProgress(value: 0.75, showPercentage: true)
```

### Circular Progress
```swift
LLCircularProgress(value: 0.50)
LLCircularProgress(value: 0.80, size: 100)
```

### Segmented Progress
```swift
LLSegmentedProgress(
    segments: [
        .init(value: 500, color: .blue, label: "Subscription"),
        .init(value: 250, color: .green, label: "Purchased"),
        .init(value: 100, color: .purple, label: "Promotional")
    ]
)
```

---

## Toast Notifications

### Setup
```swift
@State private var toast: ToastConfig?

var body: some View {
    ContentView()
        .toast($toast)
}
```

### Show Toasts
```swift
// Success
toast = .success("Purchase completed!")

// Error
toast = .error("Failed to load data")

// Warning
toast = .warning("Low credit balance")

// Info
toast = .info("New feature available")

// Loading
toast = .loading("Processing...")
```

### Custom Toast
```swift
toast = ToastConfig(
    message: "Custom message",
    style: .info,
    duration: 5.0
)
```

---

## Common Patterns

### Loading State
```swift
if isLoading {
    LLCreditCardSkeleton()
} else if let data = data {
    // Show data
} else {
    LLEmptyState(
        icon: "exclamationmark.triangle",
        title: "Error",
        message: "Failed to load",
        actionTitle: "Retry",
        action: { retry() }
    )
}
```

### List with Empty State
```swift
if items.isEmpty {
    LLEmptyState(
        icon: "tray.fill",
        title: "No Items",
        message: "Add items to get started"
    )
} else {
    ForEach(items) { item in
        ItemRow(item: item)
    }
}
```

### Confirmation with Toast
```swift
LLButton("Save") {
    Task {
        do {
            try await saveData()
            toast = .success("Saved successfully!")
        } catch {
            toast = .error("Failed to save")
        }
    }
}
```

### Progress Visualization
```swift
VStack {
    LLCircularProgress(
        value: Double(completed) / Double(total),
        size: 100
    )

    Text("\(completed)/\(total) lessons")
        .font(LLTypography.caption())
}
```

---

## Accessibility

### Always Include
```swift
// For images/icons
Image(systemName: "gear")
    .accessibilityLabel("Settings")

// For custom controls
CustomButton()
    .accessibilityLabel("Submit form")
    .accessibilityHint("Double tap to submit")

// For progress
LLLinearProgress(value: 0.75)
    // Automatically announces "Progress: 75 percent"
```

### Color Contrast
```swift
// Text on backgrounds
Text("Important")
    .foregroundColor(LLColors.foreground.color(for: colorScheme))

// Never hardcode colors - always use design system
// ❌ .foregroundColor(.black)
// ✅ .foregroundColor(LLColors.foreground.color(for: colorScheme))
```

### Touch Targets
```swift
// Minimum 44x44 points
Button { } label: {
    Image(systemName: "plus")
}
.frame(minWidth: 44, minHeight: 44)

// Or use helper
.minTouchTarget()
```

---

## Dark Mode

### Automatic Handling
All design system components automatically adapt to dark mode. Always use:

```swift
@Environment(\.colorScheme) var colorScheme

// Then use
LLColors.foreground.color(for: colorScheme)
```

### Testing
```swift
#Preview {
    MyView()
        .preferredColorScheme(.dark)
}
```

---

## Common Mistakes to Avoid

### ❌ Don't Do This
```swift
// Hardcoded colors
.foregroundColor(.black)
.background(.white)

// Hardcoded spacing
.padding(16)
.frame(height: 44)

// Inline styles
Text("Title")
    .font(.system(size: 24, weight: .bold))

// Plain spinners
ProgressView()
```

### ✅ Do This Instead
```swift
// Design system colors
.foregroundColor(LLColors.foreground.color(for: colorScheme))
.background(LLColors.background.color(for: colorScheme))

// Design system spacing
.padding(LLSpacing.md)
.frame(height: LLSpacing.buttonHeightMD)

// Typography system
Text("Title")
    .font(LLTypography.h3())

// Skeleton loaders
LLSkeletonLoader(shape: .rectangle(width: nil, height: 60))
```

---

## Preview Templates

### Light & Dark Mode
```swift
#Preview("Light") {
    MyView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    MyView()
        .preferredColorScheme(.dark)
}
```

### With Different States
```swift
#Preview("Empty") {
    MyView(items: [])
}

#Preview("Loading") {
    MyView(isLoading: true)
}

#Preview("Error") {
    MyView(error: "Network error")
}
```

---

## Resources

- **Design System Source:** `/Source/Core/DesignSystem/`
- **Components:** `/Source/Core/DesignSystem/Components/`
- **Full Documentation:** `UI_UX_IMPROVEMENTS_REPORT.md`
- **iOS HIG:** https://developer.apple.com/design/human-interface-guidelines/

---

**Last Updated:** January 21, 2026
**Maintainer:** Design System Team
