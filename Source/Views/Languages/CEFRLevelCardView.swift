//
//  CEFRLevelCardView.swift
//  LanguageLuid
//
//  Reusable CEFR level card component
//  Matches language-luid-frontend CEFRLevelCard design
//

import SwiftUI

struct CEFRLevelCardView: View {
    // MARK: - Properties

    let level: CEFRLevelData
    let languageCode: String
    let onTap: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false

    // MARK: - Computed Properties

    private var progress: Double {
        guard level.lessonCount > 0 else { return 0 }
        return Double(level.completedLessons) / Double(level.lessonCount)
    }

    private var progressPercentage: Int {
        Int(progress * 100)
    }

    private var isCompleted: Bool {
        level.completedLessons == level.lessonCount && level.lessonCount > 0
    }

    private var hasStarted: Bool {
        level.completedLessons > 0
    }

    private var canStart: Bool {
        level.isUnlocked
    }

    // MARK: - Body

    var body: some View {
        Button(action: {
            guard canStart else { return }
            onTap()
        }) {
            cardContent
        }
        .buttonStyle(CardButtonStyle(isPressed: $isPressed))
        .opacity(canStart ? 1.0 : 0.75)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }

    // MARK: - Card Content

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: LLSpacing.md) {
            // Header: Level Badge and Difficulty
            header

            // Title and Description
            titleSection

            // Stats: Lessons and Hours
            statsSection

            // Progress Bar (if started)
            if hasStarted {
                progressSection
            }

            // Skills Preview
            skillsSection

            // Action Button
            actionButton
        }
        .padding(LLSpacing.md)
        .background(
            ZStack {
                // Gradient Background
                RoundedRectangle(cornerRadius: LLSpacing.radiusLG)
                    .fill(gradientBackground)
                    .opacity(0.05)

                // Card Background
                RoundedRectangle(cornerRadius: LLSpacing.radiusLG)
                    .fill(LLColors.card.color(for: colorScheme))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: LLSpacing.radiusLG)
                .strokeBorder(
                    isCompleted
                        ? LLColors.success.color(for: colorScheme)
                        : LLColors.border.color(for: colorScheme),
                    lineWidth: isCompleted ? 2 : LLSpacing.borderStandard
                )
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
            radius: LLSpacing.shadowMDRadius,
            x: 0,
            y: LLSpacing.shadowMD
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            // Level Code Badge
            Text(level.code)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(levelColor)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(levelColor.opacity(0.15))
                )

            Spacer()

            // Status Icons and Difficulty Badge
            HStack(spacing: LLSpacing.xs) {
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(LLColors.success.color(for: colorScheme))
                }

                if !canStart {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18))
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }

                LLBadge(level.difficulty, variant: .outline, size: .sm)
            }
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: LLSpacing.xs) {
            Text(level.name)
                .font(LLTypography.h4())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            Text(level.description)
                .font(LLTypography.bodySmall())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: LLSpacing.lg) {
            // Lessons
            HStack(spacing: LLSpacing.xs) {
                Image(systemName: "book.fill")
                    .font(.system(size: 14))
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                Text("\(level.lessonCount) lessons")
                    .font(LLTypography.captionSmall())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }

            // Estimated Hours
            HStack(spacing: LLSpacing.xs) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                Text("~\(level.estimatedHours)h")
                    .font(LLTypography.captionSmall())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(spacing: LLSpacing.xs) {
            HStack {
                Text("Progress")
                    .font(LLTypography.captionSmall())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                Spacer()

                Text("\(level.completedLessons)/\(level.lessonCount)")
                    .font(LLTypography.captionSmall())
                    .fontWeight(.semibold)
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: LLSpacing.radiusFull)
                        .fill(LLColors.muted.color(for: colorScheme))
                        .frame(height: 6)

                    // Progress Fill
                    RoundedRectangle(cornerRadius: LLSpacing.radiusFull)
                        .fill(levelColor)
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Skills Section

    private var skillsSection: some View {
        VStack(alignment: .leading, spacing: LLSpacing.xs) {
            HStack(spacing: LLSpacing.xs) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                Text("What you'll learn:")
                    .font(LLTypography.captionSmall())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }

            VStack(alignment: .leading, spacing: 4) {
                ForEach(level.skills.prefix(3), id: \.self) { skill in
                    HStack(alignment: .top, spacing: LLSpacing.xs) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                            .offset(y: 2)

                        Text(skill)
                            .font(LLTypography.captionSmall())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                            .lineLimit(1)
                    }
                }

                if level.skills.count > 3 {
                    Text("+\(level.skills.count - 3) more skills...")
                        .font(LLTypography.captionSmall())
                        .italic()
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        .padding(.leading, 18)
                }
            }
        }
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Group {
            if !canStart {
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))

                    Text("Complete Previous Level")
                        .font(LLTypography.buttonSmall())
                }
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                        .fill(LLColors.muted.color(for: colorScheme))
                )
            } else if isCompleted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))

                    Text("Review Lessons")
                        .font(LLTypography.buttonSmall())
                }
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                        .fill(LLColors.muted.color(for: colorScheme))
                )
            } else if hasStarted {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14))

                    Text("Continue (\(progressPercentage)%)")
                        .font(LLTypography.buttonSmall())
                }
                .foregroundColor(LLColors.primaryForeground.color(for: colorScheme))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                        .fill(LLColors.primary.color(for: colorScheme))
                )
            } else {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14))

                    Text("Start Learning")
                        .font(LLTypography.buttonSmall())
                }
                .foregroundColor(LLColors.primaryForeground.color(for: colorScheme))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                        .fill(LLColors.primary.color(for: colorScheme))
                )
            }
        }
    }

    // MARK: - Computed Visual Properties

    private var levelColor: Color {
        switch level.code {
        case "A1", "A2":
            return LLColors.success.color(for: colorScheme)
        case "B1", "B2":
            return LLColors.info.color(for: colorScheme)
        case "C1", "C2":
            return LLColors.warning.color(for: colorScheme)
        default:
            return LLColors.primary.color(for: colorScheme)
        }
    }

    private var gradientBackground: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [levelColor.opacity(0.3), levelColor.opacity(0.1)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        "\(level.code) - \(level.name), \(level.difficulty) level"
    }

    private var accessibilityHint: String {
        if !canStart {
            return "Complete previous level to unlock"
        } else if isCompleted {
            return "Review completed lessons"
        } else if hasStarted {
            return "Continue learning, \(progressPercentage)% complete"
        } else {
            return "Start learning"
        }
    }
}

// MARK: - CEFR Level Data Model

struct CEFRLevelData {
    let code: String
    let name: String
    let description: String
    let difficulty: String
    let estimatedHours: Int
    let lessonCount: Int
    let completedLessons: Int
    let isUnlocked: Bool
    let skills: [String]
}

// MARK: - Helper Extension

extension CEFRLevelData {
    /// Create from CEFRLevel and curriculum groups
    static func from(
        level: CEFRLevel,
        groups: [CurriculumGroup],
        isUnlocked: Bool = true
    ) -> CEFRLevelData {
        let groupsForLevel = groups.filter { $0.cefrLevel == level }
        let lessonCount = groupsForLevel.reduce(0) { $0 + $1.totalLessons }
        let completedCount = groupsForLevel.reduce(0) { $0 + $1.completedLessonCount }
        let estimatedMinutes = groupsForLevel.reduce(0) { $0 + ($1.estimatedMinutes ?? 0) }

        // Get skills from objectives
        let skills = groupsForLevel
            .flatMap { $0.objectives }
            .filter { !$0.isEmpty }

        return CEFRLevelData(
            code: level.rawValue,
            name: cefrLevelName(for: level),
            description: level.description,
            difficulty: level.shortDescription,
            estimatedHours: estimatedMinutes / 60,
            lessonCount: lessonCount,
            completedLessons: completedCount,
            isUnlocked: isUnlocked,
            skills: skills.isEmpty ? defaultSkills(for: level) : skills
        )
    }

    private static func cefrLevelName(for level: CEFRLevel) -> String {
        switch level {
        case .a1: return "Beginner"
        case .a2: return "Elementary"
        case .b1: return "Intermediate"
        case .b2: return "Upper Intermediate"
        case .c1: return "Advanced"
        case .c2: return "Proficient"
        }
    }

    private static func defaultSkills(for level: CEFRLevel) -> [String] {
        switch level {
        case .a1:
            return [
                "Basic greetings and introductions",
                "Simple questions and answers",
                "Essential vocabulary for daily life"
            ]
        case .a2:
            return [
                "Describe familiar topics",
                "Basic communication in routine tasks",
                "Simple personal information"
            ]
        case .b1:
            return [
                "Handle travel situations",
                "Express opinions and experiences",
                "Understand main points of clear texts"
            ]
        case .b2:
            return [
                "Interact with fluency",
                "Understand complex texts",
                "Express ideas clearly and in detail"
            ]
        case .c1:
            return [
                "Express ideas fluently",
                "Use language flexibly",
                "Understand implicit meaning"
            ]
        case .c2:
            return [
                "Understand virtually everything",
                "Express yourself very fluently",
                "Summarize and reconstruct arguments"
            ]
        }
    }
}

// MARK: - Custom Button Style

struct CardButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Preview

#Preview("CEFR Level Cards") {
    ScrollView {
        VStack(spacing: LLSpacing.md) {
            // A1 - Locked
            CEFRLevelCardView(
                level: CEFRLevelData(
                    code: "A1",
                    name: "Beginner",
                    description: "Can understand and use familiar everyday expressions and very basic phrases.",
                    difficulty: "Beginner",
                    estimatedHours: 80,
                    lessonCount: 20,
                    completedLessons: 0,
                    isUnlocked: true,
                    skills: [
                        "Basic greetings and introductions",
                        "Simple questions and answers",
                        "Essential vocabulary for daily life",
                        "Numbers, dates, and time"
                    ]
                ),
                languageCode: "es"
            ) {
                print("A1 tapped")
            }

            // A2 - In Progress
            CEFRLevelCardView(
                level: CEFRLevelData(
                    code: "A2",
                    name: "Elementary",
                    description: "Can understand sentences related to areas of immediate relevance.",
                    difficulty: "Elementary",
                    estimatedHours: 90,
                    lessonCount: 18,
                    completedLessons: 12,
                    isUnlocked: true,
                    skills: [
                        "Describe familiar topics",
                        "Basic communication in routine tasks",
                        "Simple personal information"
                    ]
                ),
                languageCode: "es"
            ) {
                print("A2 tapped")
            }

            // B1 - Completed
            CEFRLevelCardView(
                level: CEFRLevelData(
                    code: "B1",
                    name: "Intermediate",
                    description: "Can deal with most situations while traveling.",
                    difficulty: "Intermediate",
                    estimatedHours: 100,
                    lessonCount: 22,
                    completedLessons: 22,
                    isUnlocked: true,
                    skills: [
                        "Handle travel situations",
                        "Express opinions and experiences",
                        "Understand main points of clear texts"
                    ]
                ),
                languageCode: "es"
            ) {
                print("B1 tapped")
            }

            // B2 - Locked
            CEFRLevelCardView(
                level: CEFRLevelData(
                    code: "B2",
                    name: "Upper Intermediate",
                    description: "Can interact with fluency and spontaneity.",
                    difficulty: "Upper Intermediate",
                    estimatedHours: 120,
                    lessonCount: 19,
                    completedLessons: 0,
                    isUnlocked: false,
                    skills: [
                        "Interact with fluency",
                        "Understand complex texts",
                        "Express ideas clearly"
                    ]
                ),
                languageCode: "es"
            ) {
                print("B2 tapped")
            }
        }
        .padding()
    }
}
