//
//  LessonProgressCard.swift
//  LanguageLuid
//
//  Reusable card component for displaying lesson progress
//  Used in Continue Learning view
//

import SwiftUI

struct LessonProgressCard: View {
    let lessonWithRoadmap: LessonWithRoadmap
    let style: CardStyle
    let onTap: () -> Void

    @Environment(\.colorScheme) var colorScheme

    enum CardStyle {
        case hero       // Large card with prominent CTA
        case standard   // Regular size card
        case compact    // Smaller card for grids
    }

    var body: some View {
        Button(action: onTap) {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var cardContent: some View {
        switch style {
        case .hero:
            heroCard
        case .standard:
            standardCard
        case .compact:
            compactCard
        }
    }

    // MARK: - Hero Card (Large, Prominent)

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: LLSpacing.md) {
            // Header with flag and language
            HStack(spacing: LLSpacing.sm) {
                Text(lessonWithRoadmap.languageFlag)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 2) {
                    Text(lessonWithRoadmap.languageName)
                        .font(LLTypography.bodySmall())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                    LLBadge(
                        lessonWithRoadmap.lesson.cefrLevel.rawValue.uppercased(),
                        variant: .secondary,
                        size: .sm
                    )
                }

                Spacer()

                // Phase indicator
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Phase \(lessonWithRoadmap.currentPhase)")
                        .font(LLTypography.h4())
                        .foregroundColor(LLColors.primary.color(for: colorScheme))

                    Text("of \(lessonWithRoadmap.totalPhases)")
                        .font(LLTypography.captionSmall())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
            }

            Divider()
                .background(LLColors.border.color(for: colorScheme))

            // Lesson info
            VStack(alignment: .leading, spacing: LLSpacing.xs) {
                Text(lessonWithRoadmap.lesson.title)
                    .font(LLTypography.h3())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
                    .lineLimit(2)

                if let description = lessonWithRoadmap.lesson.description {
                    Text(description)
                        .font(LLTypography.body())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        .lineLimit(2)
                }
            }

            // Progress bar
            VStack(alignment: .leading, spacing: LLSpacing.xs) {
                HStack {
                    Text("Progress")
                        .font(LLTypography.captionSmall())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                    Spacer()

                    Text("\(Int(lessonWithRoadmap.progressPercentage))%")
                        .font(LLTypography.captionSmall())
                        .foregroundColor(LLColors.primary.color(for: colorScheme))
                        .fontWeight(.semibold)
                }

                ProgressView(value: lessonWithRoadmap.progressPercentage, total: 100)
                    .tint(LLColors.primary.color(for: colorScheme))
            }

            // Resume button
            HStack {
                Spacer()

                HStack(spacing: LLSpacing.xs) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14))

                    Text("Resume Lesson")
                        .font(LLTypography.button())
                }
                .foregroundColor(LLColors.primaryForeground.color(for: colorScheme))
                .padding(.horizontal, LLSpacing.md)
                .padding(.vertical, LLSpacing.sm)
                .background(
                    Capsule()
                        .fill(LLColors.primary.color(for: colorScheme))
                )

                Spacer()
            }
            .padding(.top, LLSpacing.xs)
        }
        .padding(LLSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: LLSpacing.radiusLG)
                .fill(LLColors.card.color(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LLSpacing.radiusLG)
                .strokeBorder(LLColors.primary.color(for: colorScheme).opacity(0.3), lineWidth: 2)
        )
        .shadow(
            color: LLColors.primary.color(for: colorScheme).opacity(0.1),
            radius: LLSpacing.shadowMDRadius,
            x: 0,
            y: LLSpacing.shadowMD
        )
    }

    // MARK: - Standard Card

    private var standardCard: some View {
        VStack(alignment: .leading, spacing: LLSpacing.sm) {
            // Header
            HStack(spacing: LLSpacing.sm) {
                Text(lessonWithRoadmap.languageFlag)
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 2) {
                    Text(lessonWithRoadmap.languageName)
                        .font(LLTypography.captionSmall())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                    LLBadge(
                        lessonWithRoadmap.lesson.cefrLevel.rawValue.uppercased(),
                        variant: .secondary,
                        size: .sm
                    )
                }

                Spacer()

                Text("Phase \(lessonWithRoadmap.currentPhase)/\(lessonWithRoadmap.totalPhases)")
                    .font(LLTypography.captionSmall())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }

            // Lesson title
            Text(lessonWithRoadmap.lesson.title)
                .font(LLTypography.h4())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                .lineLimit(2)

            // Progress
            VStack(alignment: .leading, spacing: LLSpacing.xs) {
                HStack {
                    Text("\(Int(lessonWithRoadmap.progressPercentage))% Complete")
                        .font(LLTypography.captionSmall())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                    Spacer()
                }

                ProgressView(value: lessonWithRoadmap.progressPercentage, total: 100)
                    .tint(LLColors.primary.color(for: colorScheme))
            }

            // Continue button
            HStack {
                Spacer()

                HStack(spacing: LLSpacing.xs) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))

                    Text("Continue")
                        .font(LLTypography.buttonSmall())
                }
                .foregroundColor(LLColors.primaryForeground.color(for: colorScheme))
                .padding(.horizontal, LLSpacing.sm)
                .padding(.vertical, LLSpacing.xs)
                .background(
                    Capsule()
                        .fill(LLColors.primary.color(for: colorScheme))
                )
            }
        }
        .padding(LLSpacing.md)
        .frame(height: 180)
        .background(
            RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                .fill(LLColors.card.color(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                .strokeBorder(LLColors.border.color(for: colorScheme), lineWidth: LLSpacing.borderStandard)
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05),
            radius: LLSpacing.shadowSMRadius,
            x: 0,
            y: LLSpacing.shadowSM
        )
    }

    // MARK: - Compact Card

    private var compactCard: some View {
        VStack(alignment: .leading, spacing: LLSpacing.sm) {
            // Header
            HStack {
                Text(lessonWithRoadmap.languageFlag)
                    .font(.system(size: 20))

                Spacer()

                LLBadge(
                    lessonWithRoadmap.lesson.cefrLevel.rawValue.uppercased(),
                    variant: .secondary,
                    size: .sm
                )
            }

            // Title
            Text(lessonWithRoadmap.lesson.title)
                .font(LLTypography.bodyMedium())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                .lineLimit(2)
                .frame(height: 40, alignment: .top)

            Spacer()

            // Duration or phase
            HStack(spacing: LLSpacing.xs) {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                Text("\(lessonWithRoadmap.lesson.estimatedMinutes)min")
                    .font(LLTypography.captionSmall())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 10))
                    .foregroundColor(LLColors.primary.color(for: colorScheme))
            }
        }
        .padding(LLSpacing.sm)
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                .fill(LLColors.card.color(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                .strokeBorder(LLColors.border.color(for: colorScheme), lineWidth: LLSpacing.borderStandard)
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05),
            radius: LLSpacing.shadowSMRadius,
            x: 0,
            y: LLSpacing.shadowSM
        )
    }
}

// MARK: - Preview
// TODO: Fix preview - needs mock data
/*
#Preview("Hero Card") {
    LessonProgressCard(
        lessonWithRoadmap: LessonWithRoadmap.mock,
        style: .hero,
        onTap: {}
    )
    .padding()
}

#Preview("Standard Card") {
    LessonProgressCard(
        lessonWithRoadmap: LessonWithRoadmap.mock,
        style: .standard,
        onTap: {}
    )
    .padding()
}

#Preview("Compact Card") {
    LessonProgressCard(
        lessonWithRoadmap: LessonWithRoadmap.mock,
        style: .compact,
        onTap: {}
    )
    .padding()
}
*/
