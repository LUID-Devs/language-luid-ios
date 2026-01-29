//
//  ActivityTimelineItem.swift
//  LanguageLuid
//
//  Timeline item component for recently completed lessons
//  Used in Continue Learning view
//

import SwiftUI

struct ActivityTimelineItem: View {
    let lessonWithRoadmap: LessonWithRoadmap
    let isLast: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: LLSpacing.md) {
                // Timeline indicator
                VStack(spacing: 0) {
                    // Checkmark circle
                    ZStack {
                        Circle()
                            .fill(LLColors.success.color(for: colorScheme))
                            .frame(width: 32, height: 32)

                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }

                    // Connecting line (if not last item)
                    if !isLast {
                        Rectangle()
                            .fill(LLColors.border.color(for: colorScheme))
                            .frame(width: 2)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(width: 32)

                // Content
                VStack(alignment: .leading, spacing: LLSpacing.sm) {
                    // Header with time and language
                    HStack(spacing: LLSpacing.xs) {
                        Text(lessonWithRoadmap.timeAgo)
                            .font(LLTypography.captionSmall())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                        Text("•")
                            .font(LLTypography.captionSmall())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                        Text(lessonWithRoadmap.languageFlag)
                            .font(.system(size: 14))

                        Text(lessonWithRoadmap.languageName)
                            .font(LLTypography.captionSmall())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                        Spacer()

                        // Score badge
                        if lessonWithRoadmap.scorePercentage > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(LLColors.warning.color(for: colorScheme))

                                Text("\(lessonWithRoadmap.scorePercentage)%")
                                    .font(LLTypography.captionSmall())
                                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, LLSpacing.xs)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(LLColors.warning.color(for: colorScheme).opacity(0.1))
                            )
                        }
                    }

                    // Lesson info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lessonWithRoadmap.lesson.title)
                            .font(LLTypography.bodyMedium())
                            .foregroundColor(LLColors.foreground.color(for: colorScheme))
                            .lineLimit(2)

                        HStack(spacing: LLSpacing.xs) {
                            LLBadge(
                                lessonWithRoadmap.lesson.cefrLevel.rawValue.uppercased(),
                                variant: .secondary,
                                size: .sm
                            )

                            Text("•")
                                .font(LLTypography.captionSmall())
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                            Text(lessonWithRoadmap.lesson.category.displayName)
                                .font(LLTypography.captionSmall())
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }
                    }

                    // Divider (if not last)
                    if !isLast {
                        Divider()
                            .background(LLColors.border.color(for: colorScheme))
                            .padding(.top, LLSpacing.sm)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, isLast ? 0 : LLSpacing.sm)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
// TODO: Fix preview - needs mock data
/*
#Preview("Activity Timeline Item") {
    VStack(spacing: 0) {
        ActivityTimelineItem(
            lessonWithRoadmap: LessonWithRoadmap.mock1,
            isLast: false,
            onTap: {}
        )
        ActivityTimelineItem(
            lessonWithRoadmap: LessonWithRoadmap.mock2,
            isLast: false,
            onTap: {}
        )
        ActivityTimelineItem(
            lessonWithRoadmap: LessonWithRoadmap.mock3,
            isLast: true,
            onTap: {}
        )
    }
    .padding()
}
*/
