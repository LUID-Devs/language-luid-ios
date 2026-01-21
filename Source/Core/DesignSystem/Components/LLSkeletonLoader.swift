//
//  LLSkeletonLoader.swift
//  LanguageLuid
//
//  Design System - Skeleton Loader Component
//  Animated loading placeholders for better perceived performance
//

import SwiftUI

/// Skeleton loader shape variants
enum LLSkeletonShape {
    case rectangle(width: CGFloat?, height: CGFloat)
    case circle(diameter: CGFloat)
    case roundedRectangle(width: CGFloat?, height: CGFloat, cornerRadius: CGFloat)
    case text(lines: Int, lineSpacing: CGFloat)
}

/// Animated skeleton loader component
struct LLSkeletonLoader: View {
    // MARK: - Properties

    let shape: LLSkeletonShape
    @Environment(\.colorScheme) var colorScheme
    @State private var isAnimating = false

    // MARK: - Initializer

    init(shape: LLSkeletonShape) {
        self.shape = shape
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch shape {
            case .rectangle(let width, let height):
                Rectangle()
                    .frame(width: width, height: height)
            case .circle(let diameter):
                Circle()
                    .frame(width: diameter, height: diameter)
            case .roundedRectangle(let width, let height, let cornerRadius):
                RoundedRectangle(cornerRadius: cornerRadius)
                    .frame(width: width, height: height)
            case .text(let lines, let lineSpacing):
                textSkeleton(lines: lines, spacing: lineSpacing)
            }
        }
        .foregroundColor(skeletonColor)
        .overlay(shimmerOverlay)
        .onAppear {
            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }

    // MARK: - Skeleton Color

    private var skeletonColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color.black.opacity(0.06)
    }

    // MARK: - Shimmer Overlay

    private var shimmerOverlay: some View {
        GeometryReader { geometry in
            LinearGradient(
                colors: [
                    Color.clear,
                    shimmerHighlight,
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 2)
            .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
        }
        .clipped()
    }

    private var shimmerHighlight: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.15)
            : Color.white.opacity(0.6)
    }

    // MARK: - Text Skeleton

    private func textSkeleton(lines: Int, spacing: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(0..<lines, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .frame(height: 12)
                    .frame(maxWidth: index == lines - 1 ? .infinity * 0.7 : .infinity)
            }
        }
    }
}

// MARK: - Credit Card Skeleton

struct LLCreditCardSkeleton: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        LLCard(style: .standard, padding: .lg) {
            VStack(spacing: LLSpacing.lg) {
                HStack {
                    VStack(alignment: .leading, spacing: LLSpacing.xs) {
                        LLSkeletonLoader(shape: .roundedRectangle(width: 120, height: 20, cornerRadius: 4))
                        LLSkeletonLoader(shape: .roundedRectangle(width: 200, height: 14, cornerRadius: 4))
                    }
                    Spacer()
                    LLSkeletonLoader(shape: .circle(diameter: 36))
                }

                LLSkeletonLoader(shape: .roundedRectangle(width: nil, height: 80, cornerRadius: LLSpacing.radiusMD))

                VStack(spacing: LLSpacing.sm) {
                    ForEach(0..<3, id: \.self) { _ in
                        HStack {
                            LLSkeletonLoader(shape: .circle(diameter: 32))
                            VStack(alignment: .leading, spacing: 4) {
                                LLSkeletonLoader(shape: .roundedRectangle(width: 100, height: 12, cornerRadius: 4))
                                LLSkeletonLoader(shape: .roundedRectangle(width: 60, height: 16, cornerRadius: 4))
                            }
                            Spacer()
                        }
                        .padding(LLSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                                .fill(LLColors.muted.color(for: colorScheme))
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Transaction Row Skeleton

struct LLTransactionRowSkeleton: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: LLSpacing.md) {
            LLSkeletonLoader(shape: .circle(diameter: 40))

            VStack(alignment: .leading, spacing: 4) {
                LLSkeletonLoader(shape: .roundedRectangle(width: 150, height: 14, cornerRadius: 4))
                LLSkeletonLoader(shape: .roundedRectangle(width: 100, height: 12, cornerRadius: 4))
            }

            Spacer()

            LLSkeletonLoader(shape: .roundedRectangle(width: 60, height: 20, cornerRadius: 4))
        }
        .padding(LLSpacing.md)
    }
}

// MARK: - Preview

#Preview("Skeleton Loaders") {
    ScrollView {
        VStack(spacing: LLSpacing.xl) {
            // Basic Shapes
            VStack(alignment: .leading, spacing: LLSpacing.md) {
                Text("Basic Shapes")
                    .font(LLTypography.h4())

                LLSkeletonLoader(shape: .rectangle(width: nil, height: 60))
                LLSkeletonLoader(shape: .circle(diameter: 60))
                LLSkeletonLoader(shape: .roundedRectangle(width: nil, height: 100, cornerRadius: 12))
            }

            Divider()

            // Text Lines
            VStack(alignment: .leading, spacing: LLSpacing.md) {
                Text("Text Lines")
                    .font(LLTypography.h4())

                LLSkeletonLoader(shape: .text(lines: 3, lineSpacing: 8))
            }

            Divider()

            // Credit Card Skeleton
            VStack(alignment: .leading, spacing: LLSpacing.md) {
                Text("Credit Card Skeleton")
                    .font(LLTypography.h4())

                LLCreditCardSkeleton()
            }

            Divider()

            // Transaction Row Skeleton
            VStack(alignment: .leading, spacing: LLSpacing.md) {
                Text("Transaction Row Skeleton")
                    .font(LLTypography.h4())

                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { index in
                        LLTransactionRowSkeleton()
                        if index < 2 {
                            Divider()
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: LLSpacing.radiusLG)
                        .fill(Color(uiColor: .systemBackground))
                )
            }
        }
        .padding()
    }
}
