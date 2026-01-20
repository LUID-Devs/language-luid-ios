//
//  LLLoadingView.swift
//  LanguageLuid
//
//  Design System - Loading Indicators
//  Reusable loading states and skeleton screens
//

import SwiftUI

// MARK: - Loading Spinner

/// Custom loading spinner with design system colors
struct LLSpinner: View {
    let size: LLSpinnerSize
    let color: ColorSet?

    @Environment(\.colorScheme) var colorScheme
    @State private var isAnimating = false

    enum LLSpinnerSize {
        case sm
        case md
        case lg

        var dimension: CGFloat {
            switch self {
            case .sm: return 16
            case .md: return 24
            case .lg: return 40
            }
        }

        var lineWidth: CGFloat {
            switch self {
            case .sm: return 2
            case .md: return 3
            case .lg: return 4
            }
        }
    }

    init(size: LLSpinnerSize = .md, color: ColorSet? = nil) {
        self.size = size
        self.color = color
    }

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                spinnerColor,
                style: StrokeStyle(
                    lineWidth: size.lineWidth,
                    lineCap: .round
                )
            )
            .frame(width: size.dimension, height: size.dimension)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(
                Animation.linear(duration: 1)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }

    private var spinnerColor: Color {
        color?.color(for: colorScheme) ?? LLColors.primary.color(for: colorScheme)
    }
}

// MARK: - Loading Overlay

/// Full-screen loading overlay
struct LLLoadingOverlay: View {
    let message: String?
    @Environment(\.colorScheme) var colorScheme

    init(message: String? = nil) {
        self.message = message
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: LLSpacing.md) {
                LLSpinner(size: .lg)

                if let message = message {
                    Text(message)
                        .font(LLTypography.body())
                        .foregroundColor(LLColors.foreground.color(for: colorScheme))
                }
            }
            .padding(LLSpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: LLSpacing.radiusLG)
                    .fill(LLColors.card.color(for: colorScheme))
            )
            .shadow(
                color: Color.black.opacity(0.3),
                radius: LLSpacing.shadowLGRadius,
                x: 0,
                y: LLSpacing.shadowLG
            )
        }
    }
}

// MARK: - Progress Bar

/// Horizontal progress bar
struct LLProgressBar: View {
    let progress: Double // 0.0 to 1.0
    let height: CGFloat
    let backgroundColor: ColorSet?
    let foregroundColor: ColorSet?
    let showPercentage: Bool
    let animated: Bool

    @Environment(\.colorScheme) var colorScheme
    @State private var animatedProgress: Double = 0

    init(
        progress: Double,
        height: CGFloat = LLSpacing.progressBarHeight,
        backgroundColor: ColorSet? = nil,
        foregroundColor: ColorSet? = nil,
        showPercentage: Bool = false,
        animated: Bool = true
    ) {
        self.progress = min(max(progress, 0), 1)
        self.height = height
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.showPercentage = showPercentage
        self.animated = animated
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: LLSpacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: LLSpacing.radiusFull)
                        .fill(bgColor)
                        .frame(height: height)

                    // Foreground
                    RoundedRectangle(cornerRadius: LLSpacing.radiusFull)
                        .fill(fgColor)
                        .frame(
                            width: geometry.size.width * (animated ? animatedProgress : progress),
                            height: height
                        )
                        .animation(animated ? .easeInOut(duration: 0.8) : nil, value: animatedProgress)
                }
            }
            .frame(height: height)

            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(LLTypography.captionSmall())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
        }
        .onAppear {
            if animated {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            if animated {
                animatedProgress = newValue
            }
        }
    }

    private var bgColor: Color {
        backgroundColor?.color(for: colorScheme) ?? LLColors.muted.color(for: colorScheme)
    }

    private var fgColor: Color {
        foregroundColor?.color(for: colorScheme) ?? LLColors.primary.color(for: colorScheme)
    }
}

// MARK: - Circular Progress

/// Circular progress indicator
struct LLCircularProgress: View {
    let progress: Double // 0.0 to 1.0
    let size: CGFloat
    let lineWidth: CGFloat
    let backgroundColor: ColorSet?
    let foregroundColor: ColorSet?
    let showPercentage: Bool

    @Environment(\.colorScheme) var colorScheme
    @State private var animatedProgress: Double = 0

    init(
        progress: Double,
        size: CGFloat = 60,
        lineWidth: CGFloat = 6,
        backgroundColor: ColorSet? = nil,
        foregroundColor: ColorSet? = nil,
        showPercentage: Bool = true
    ) {
        self.progress = min(max(progress, 0), 1)
        self.size = size
        self.lineWidth = lineWidth
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.showPercentage = showPercentage
    }

    var body: some View {
        ZStack {
            // Background Circle
            Circle()
                .stroke(
                    bgColor,
                    lineWidth: lineWidth
                )

            // Progress Circle
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    fgColor,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeInOut(duration: 0.8), value: animatedProgress)

            // Percentage Text
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(LLTypography.h6())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { oldValue, newValue in
            animatedProgress = newValue
        }
    }

    private var bgColor: Color {
        backgroundColor?.color(for: colorScheme) ?? LLColors.muted.color(for: colorScheme)
    }

    private var fgColor: Color {
        foregroundColor?.color(for: colorScheme) ?? LLColors.primary.color(for: colorScheme)
    }
}

// MARK: - Skeleton Loading

/// Skeleton loading placeholder
struct LLSkeleton: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat

    @Environment(\.colorScheme) var colorScheme
    @State private var shimmerOffset: CGFloat = -200

    init(
        width: CGFloat? = nil,
        height: CGFloat = 16,
        cornerRadius: CGFloat = LLSpacing.radiusSM
    ) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(LLColors.muted.color(for: colorScheme))
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                LLColors.border.color(for: colorScheme).opacity(0.5),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: shimmerOffset
                    )
            )
            .clipped()
            .onAppear {
                shimmerOffset = 400
            }
    }
}

// MARK: - Skeleton Card

/// Skeleton loading card
struct LLSkeletonCard: View {
    let includeImage: Bool

    init(includeImage: Bool = true) {
        self.includeImage = includeImage
    }

    var body: some View {
        LLCard(style: .standard, padding: .md) {
            VStack(alignment: .leading, spacing: LLSpacing.md) {
                if includeImage {
                    LLSkeleton(height: 160, cornerRadius: LLSpacing.radiusMD)
                }

                VStack(alignment: .leading, spacing: LLSpacing.sm) {
                    LLSkeleton(width: 200, height: 24)
                    LLSkeleton(width: 150, height: 16)
                    LLSkeleton(height: 16)
                    LLSkeleton(width: 180, height: 16)
                }
            }
        }
    }
}

// MARK: - Skeleton List

/// Skeleton loading list
struct LLSkeletonList: View {
    let count: Int
    let spacing: CGFloat

    init(count: Int = 3, spacing: CGFloat = LLSpacing.md) {
        self.count = count
        self.spacing = spacing
    }

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0..<count, id: \.self) { _ in
                HStack(spacing: LLSpacing.md) {
                    LLSkeleton(width: 48, height: 48, cornerRadius: LLSpacing.radiusFull)

                    VStack(alignment: .leading, spacing: LLSpacing.xs) {
                        LLSkeleton(width: 120, height: 16)
                        LLSkeleton(width: 180, height: 14)
                    }

                    Spacer()
                }
            }
        }
    }
}

// MARK: - Pulse Animation

/// Pulsing view for loading states
struct LLPulse: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.6 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    /// Apply pulse animation for loading states
    func pulse() -> some View {
        self.modifier(LLPulse())
    }
}

// MARK: - Empty State

/// Empty state view
struct LLEmptyState: View {
    let icon: Image
    let title: String
    let description: String
    let actionTitle: String?
    let action: (() -> Void)?

    @Environment(\.colorScheme) var colorScheme

    init(
        icon: Image,
        title: String,
        description: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: LLSpacing.lg) {
            icon
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: LLSpacing.iconXXL, height: LLSpacing.iconXXL)
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

            VStack(spacing: LLSpacing.sm) {
                Text(title)
                    .font(LLTypography.h4())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))

                Text(description)
                    .font(LLTypography.body())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                LLButton(actionTitle, style: .primary, action: action)
            }
        }
        .padding(LLSpacing.xl)
    }
}

// MARK: - Loading State Enum

/// Loading state for views
enum LLLoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case error(Error)

    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    var data: T? {
        if case .loaded(let data) = self {
            return data
        }
        return nil
    }

    var error: Error? {
        if case .error(let error) = self {
            return error
        }
        return nil
    }
}

// MARK: - Loading State View Builder

extension View {
    /// Show loading state with content
    func loadingState<T>(
        _ state: LLLoadingState<T>,
        @ViewBuilder content: @escaping (T) -> some View,
        @ViewBuilder placeholder: @escaping () -> some View = { LLSkeletonCard() },
        @ViewBuilder error: @escaping (Error) -> some View = { _ in
            LLEmptyState(
                icon: Image(systemName: "exclamationmark.triangle"),
                title: "Something went wrong",
                description: "Please try again later"
            )
        }
    ) -> some View {
        Group {
            switch state {
            case .idle:
                EmptyView()
            case .loading:
                placeholder()
            case .loaded(let data):
                content(data)
            case .error(let err):
                error(err)
            }
        }
    }
}

// MARK: - Preview

#Preview("Loading Views") {
    ScrollView {
        VStack(spacing: LLSpacing.xl) {
            // Spinners
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Spinners")
                    .font(LLTypography.h4())

                HStack(spacing: LLSpacing.lg) {
                    LLSpinner(size: .sm)
                    LLSpinner(size: .md)
                    LLSpinner(size: .lg)
                }
            }

            Divider()

            // Progress Bars
            VStack(alignment: .leading, spacing: LLSpacing.md) {
                Text("Progress Bars")
                    .font(LLTypography.h4())

                LLProgressBar(progress: 0.3)
                LLProgressBar(progress: 0.6, showPercentage: true)
                LLProgressBar(progress: 0.9, height: 12)
            }

            Divider()

            // Circular Progress
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Circular Progress")
                    .font(LLTypography.h4())

                HStack(spacing: LLSpacing.lg) {
                    LLCircularProgress(progress: 0.25, size: 60)
                    LLCircularProgress(progress: 0.65, size: 80, lineWidth: 8)
                    LLCircularProgress(progress: 1.0, size: 60)
                }
            }

            Divider()

            // Skeletons
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Skeleton Loading")
                    .font(LLTypography.h4())

                VStack(alignment: .leading, spacing: LLSpacing.sm) {
                    LLSkeleton(height: 24)
                    LLSkeleton(width: 200, height: 16)
                    LLSkeleton(width: 150, height: 16)
                }
            }

            Divider()

            // Skeleton Card
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Skeleton Card")
                    .font(LLTypography.h4())

                LLSkeletonCard()
            }

            Divider()

            // Skeleton List
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Skeleton List")
                    .font(LLTypography.h4())

                LLSkeletonList(count: 3)
            }

            Divider()

            // Empty State
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text("Empty State")
                    .font(LLTypography.h4())

                LLEmptyState(
                    icon: Image(systemName: "tray"),
                    title: "No lessons yet",
                    description: "Start learning by selecting a language",
                    actionTitle: "Browse Languages",
                    action: { print("Browse tapped") }
                )
            }
        }
        .padding()
    }
}

#Preview("Loading Overlay") {
    ZStack {
        VStack(spacing: LLSpacing.md) {
            Text("Content Behind Overlay")
                .font(LLTypography.h3())
        }

        LLLoadingOverlay(message: "Loading...")
    }
}
