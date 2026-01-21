//
//  LLProgressIndicator.swift
//  LanguageLuid
//
//  Design System - Progress Indicator Component
//  Reusable progress bars and circular indicators
//

import SwiftUI

/// Progress indicator style variants
enum LLProgressStyle {
    case linear
    case circular
    case ring
}

/// Linear progress bar component
struct LLLinearProgress: View {
    // MARK: - Properties

    let value: Double // 0.0 to 1.0
    let height: CGFloat
    let backgroundColor: Color?
    let foregroundColor: Color?
    let cornerRadius: CGFloat
    let showPercentage: Bool

    @Environment(\.colorScheme) var colorScheme

    // MARK: - Initializer

    init(
        value: Double,
        height: CGFloat = LLSpacing.progressBarHeight,
        backgroundColor: Color? = nil,
        foregroundColor: Color? = nil,
        cornerRadius: CGFloat = LLSpacing.radiusFull,
        showPercentage: Bool = false
    ) {
        self.value = max(0, min(1, value))
        self.height = height
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.cornerRadius = cornerRadius
        self.showPercentage = showPercentage
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .trailing, spacing: LLSpacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            backgroundColor ?? LLColors.muted.color(for: colorScheme)
                        )
                        .frame(height: height)

                    // Foreground progress
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            foregroundColor ?? LLColors.primary.color(for: colorScheme)
                        )
                        .frame(width: geometry.size.width * value, height: height)
                        .animation(.easeInOut(duration: 0.3), value: value)
                }
            }
            .frame(height: height)

            if showPercentage {
                Text("\(Int(value * 100))%")
                    .font(LLTypography.caption())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
        }
        .accessibilityLabel("Progress: \(Int(value * 100)) percent")
    }
}

/// Circular progress indicator
struct LLCircularProgress: View {
    // MARK: - Properties

    let value: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let size: CGFloat
    let foregroundColor: Color?
    let backgroundColor: Color?
    let showPercentage: Bool

    @Environment(\.colorScheme) var colorScheme

    // MARK: - Initializer

    init(
        value: Double,
        lineWidth: CGFloat = 8,
        size: CGFloat = 60,
        foregroundColor: Color? = nil,
        backgroundColor: Color? = nil,
        showPercentage: Bool = true
    ) {
        self.value = max(0, min(1, value))
        self.lineWidth = lineWidth
        self.size = size
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.showPercentage = showPercentage
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    backgroundColor ?? LLColors.muted.color(for: colorScheme),
                    lineWidth: lineWidth
                )

            // Progress arc
            Circle()
                .trim(from: 0, to: value)
                .stroke(
                    foregroundColor ?? LLColors.primary.color(for: colorScheme),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: value)

            // Percentage text
            if showPercentage {
                VStack(spacing: 2) {
                    Text("\(Int(value * 100))")
                        .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))

                    Text("%")
                        .font(.system(size: size * 0.15))
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Progress: \(Int(value * 100)) percent")
    }
}

/// Multi-segment progress bar for credit breakdown
struct LLSegmentedProgress: View {
    // MARK: - Properties

    struct Segment: Identifiable {
        let id = UUID()
        let value: Int
        let color: Color
        let label: String
    }

    let segments: [Segment]
    let height: CGFloat

    @Environment(\.colorScheme) var colorScheme

    // MARK: - Initializer

    init(segments: [Segment], height: CGFloat = LLSpacing.progressBarHeight) {
        self.segments = segments
        self.height = height
    }

    // MARK: - Body

    var body: some View {
        let total = Double(segments.reduce(0) { $0 + $1.value })

        VStack(alignment: .leading, spacing: LLSpacing.sm) {
            // Progress bar
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    ForEach(segments) { segment in
                        let width = total > 0
                            ? geometry.size.width * (Double(segment.value) / total)
                            : 0

                        RoundedRectangle(cornerRadius: height / 2)
                            .fill(segment.color)
                            .frame(width: max(0, width), height: height)
                    }
                }
            }
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(LLColors.muted.color(for: colorScheme))
            )

            // Legend
            VStack(alignment: .leading, spacing: LLSpacing.xs) {
                ForEach(segments) { segment in
                    HStack(spacing: LLSpacing.xs) {
                        Circle()
                            .fill(segment.color)
                            .frame(width: 8, height: 8)

                        Text(segment.label)
                            .font(LLTypography.caption())
                            .foregroundColor(LLColors.foreground.color(for: colorScheme))

                        Text("\(segment.value)")
                            .font(LLTypography.caption())
                            .fontWeight(.semibold)
                            .foregroundColor(LLColors.foreground.color(for: colorScheme))
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Progress Indicators") {
    ScrollView {
        VStack(spacing: LLSpacing.xxl) {
            // Linear Progress
            VStack(alignment: .leading, spacing: LLSpacing.md) {
                Text("Linear Progress")
                    .font(LLTypography.h4())

                LLLinearProgress(value: 0.35, showPercentage: true)
                LLLinearProgress(value: 0.65, showPercentage: true)
                LLLinearProgress(value: 0.90, showPercentage: true)
            }

            Divider()

            // Circular Progress
            VStack(alignment: .leading, spacing: LLSpacing.md) {
                Text("Circular Progress")
                    .font(LLTypography.h4())

                HStack(spacing: LLSpacing.xl) {
                    LLCircularProgress(value: 0.25, size: 80)
                    LLCircularProgress(value: 0.50, size: 80)
                    LLCircularProgress(value: 0.75, size: 80)
                }
            }

            Divider()

            // Segmented Progress
            VStack(alignment: .leading, spacing: LLSpacing.md) {
                Text("Segmented Progress")
                    .font(LLTypography.h4())

                LLSegmentedProgress(
                    segments: [
                        .init(value: 500, color: .blue, label: "Subscription"),
                        .init(value: 250, color: .green, label: "Purchased"),
                        .init(value: 100, color: .purple, label: "Promotional")
                    ]
                )
            }
        }
        .padding()
    }
}
