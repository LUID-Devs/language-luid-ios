//
//  InfoScreens.swift
//  LanguageLuid
//
//  In-app informational screens for pricing, policies, and product info.
//

import SwiftUI

struct InfoSectionData: Identifiable {
    let id: String
    let title: String
    let body: String?
    let bullets: [String]
    let footer: String?

    init(
        title: String,
        body: String? = nil,
        bullets: [String] = [],
        footer: String? = nil
    ) {
        self.id = title
        self.title = title
        self.body = body
        self.bullets = bullets
        self.footer = footer
    }
}

struct InfoScreen: View {
    let title: String
    let subtitle: String?
    let lastUpdated: String?
    let sections: [InfoSectionData]

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LLSpacing.lg) {
                header

                ForEach(sections) { section in
                    sectionCard(section)
                }
            }
            .padding(.horizontal, LLSpacing.md)
            .padding(.vertical, LLSpacing.lg)
        }
        .background(LLColors.background.color(for: colorScheme))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: LLSpacing.xs) {
            Text(title)
                .font(LLTypography.h2())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(LLTypography.body())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }

            if let lastUpdated, !lastUpdated.isEmpty {
                Text("Last updated: \(lastUpdated)")
                    .font(LLTypography.captionSmall())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
        }
    }

    private func sectionCard(_ section: InfoSectionData) -> some View {
        LLCard(style: .standard, padding: .lg) {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                Text(section.title)
                    .font(LLTypography.h4())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))

                if let body = section.body, !body.isEmpty {
                    Text(body)
                        .font(LLTypography.body())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !section.bullets.isEmpty {
                    VStack(alignment: .leading, spacing: LLSpacing.xs) {
                        ForEach(section.bullets, id: \.self) { bullet in
                            HStack(alignment: .top, spacing: LLSpacing.xs) {
                                Text("•")
                                    .font(LLTypography.body())
                                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                Text(bullet)
                                    .font(LLTypography.bodySmall())
                                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.top, 2)
                }

                if let footer = section.footer, !footer.isEmpty {
                    Text(footer)
                        .font(LLTypography.captionLarge())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - Pricing

struct PricingInfoView: View {
    private let sections: [InfoSectionData] = [
        InfoSectionData(
            title: "Free",
            body: "Perfect for getting started with speech-first learning.",
            bullets: [
                "5 lessons per month",
                "Basic pronunciation feedback",
                "1 weekend challenge",
                "Progress tracking",
                "Community access"
            ]
        ),
        InfoSectionData(
            title: "Pro",
            body: "Unlock premium learning features through LuidHub Pro.",
            bullets: [
                "Unlimited lessons",
                "Advanced speech analysis",
                "Detailed analytics and progress",
                "Exclusive challenges",
                "Priority feature access"
            ]
        ),
        InfoSectionData(
            title: "Enterprise",
            body: "Custom plans for teams and organizations.",
            bullets: [
                "Custom onboarding",
                "Team reporting",
                "Admin controls",
                "Dedicated support"
            ]
        )
    ]

    var body: some View {
        InfoScreen(
            title: "Pricing",
            subtitle: "Choose a plan that fits your learning goals.",
            lastUpdated: nil,
            sections: sections
        )
    }
}

// MARK: - How It Works

struct HowItWorksView: View {
    private let sections: [InfoSectionData] = [
        InfoSectionData(
            title: "Steps",
            bullets: [
                "Choose your language and start from A1.",
                "Follow the structured roadmap and phases.",
                "Practice speaking in every lesson.",
                "Get pronunciation feedback instantly.",
                "Track progress and build your streak."
            ]
        ),
        InfoSectionData(
            title: "What Makes LuidSpeak Different",
            bullets: [
                "Speaking from day one",
                "Real-time feedback",
                "Native speaker audio",
                "Pay for what you use"
            ]
        ),
        InfoSectionData(
            title: "FAQ",
            bullets: [
                "Credits: Each lesson uses one credit managed by LuidHub.",
                "Languages: English, Spanish, French, German, Italian; more coming soon.",
                "Microphone: Required for speech practice.",
                "Accuracy: Uses cloud speech recognition for reliable feedback."
            ]
        )
    ]

    var body: some View {
        InfoScreen(
            title: "How It Works",
            subtitle: "Learn languages the natural way by speaking from day one.",
            lastUpdated: nil,
            sections: sections
        )
    }
}

// MARK: - About

struct AboutView: View {
    private let sections: [InfoSectionData] = [
        InfoSectionData(
            title: "The Story",
            body: "LuidSpeak focuses on speaking first so learners build confidence and fluency early."
        ),
        InfoSectionData(
            title: "Our Approach",
            bullets: [
                "Speech-first learning",
                "Real-time pronunciation feedback",
                "Structured roadmaps and progress tracking",
                "Fair, credit-based pricing"
            ]
        ),
        InfoSectionData(
            title: "Luid Suite",
            bullets: [
                "TaskLuid: Task and project management",
                "ResumeLuid: AI-powered resume builder",
                "LuidKit: Developer tools and utilities",
                "RoomLuid: Room and space planning",
                "LuidGPT: AI assistant and chat",
                "LuidSpeak: Speech-first language learning"
            ]
        ),
        InfoSectionData(
            title: "Indie Development",
            bullets: [
                "Direct communication and feedback",
                "Transparent practices",
                "Community-driven roadmap"
            ]
        )
    ]

    var body: some View {
        InfoScreen(
            title: "About LuidSpeak",
            subtitle: "Part of Luid Suite, built by an independent developer.",
            lastUpdated: nil,
            sections: sections
        )
    }
}

// MARK: - Contact

struct ContactView: View {
    private let sections: [InfoSectionData] = [
        InfoSectionData(
            title: "Contact Options",
            bullets: [
                "General Support: Questions about your account or lessons.",
                "Send Feedback: Ideas for improvements or features.",
                "Report a Bug: Share issues you encounter."
            ]
        ),
        InfoSectionData(
            title: "Email",
            bullets: [
                "support@luidspeak.com",
                "support@luidhub.com (LuidHub-related)"
            ]
        ),
        InfoSectionData(
            title: "Response Time",
            body: "We typically respond within 24-48 hours."
        )
    ]

    var body: some View {
        InfoScreen(
            title: "Contact",
            subtitle: "We would love to hear from you.",
            lastUpdated: nil,
            sections: sections
        )
    }
}

// MARK: - Privacy Policy

struct PrivacyPolicyView: View {
    private let sections: [InfoSectionData] = [
        InfoSectionData(
            title: "Introduction",
            body: "This policy explains how we collect, use, and protect your information."
        ),
        InfoSectionData(
            title: "Information We Collect",
            bullets: [
                "Account information (email, profile, preferences)",
                "Learning data (lessons, progress, streaks)",
                "Technical data (device info, usage, error logs)"
            ]
        ),
        InfoSectionData(
            title: "How We Use Information",
            bullets: [
                "Provide the service and track progress",
                "Process speech recognition feedback",
                "Improve features and maintain security"
            ]
        ),
        InfoSectionData(
            title: "Third-Party Services",
            bullets: [
                "Google Cloud Speech-to-Text",
                "Google Cloud Text-to-Speech",
                "LuidHub for authentication and credits"
            ]
        ),
        InfoSectionData(
            title: "Your Rights",
            bullets: [
                "Access and correct your data",
                "Request deletion",
                "Export learning progress"
            ],
            footer: "Contact support@luidspeak.com to exercise these rights."
        ),
        InfoSectionData(
            title: "Children's Privacy",
            body: "LuidSpeak is not intended for children under 13."
        ),
        InfoSectionData(
            title: "Changes",
            body: "We may update this policy and will adjust the last updated date."
        ),
        InfoSectionData(
            title: "Contact",
            body: "Email: support@luidspeak.com or support@luidhub.com"
        )
    ]

    var body: some View {
        InfoScreen(
            title: "Privacy Policy",
            subtitle: nil,
            lastUpdated: "January 2025",
            sections: sections
        )
    }
}

// MARK: - Terms of Service

struct TermsOfServiceView: View {
    private let sections: [InfoSectionData] = [
        InfoSectionData(
            title: "Agreement to Terms",
            body: "By using LuidSpeak, you agree to these terms."
        ),
        InfoSectionData(
            title: "Description of Service",
            bullets: [
                "Speech recognition practice",
                "Structured lessons and roadmaps",
                "Progress tracking and streaks"
            ]
        ),
        InfoSectionData(
            title: "Account Registration",
            bullets: [
                "Provide accurate information",
                "Maintain account security",
                "You must be at least 13 years old"
            ]
        ),
        InfoSectionData(
            title: "Credits and Payment",
            bullets: [
                "Credits are managed through LuidHub",
                "Each lesson consumes one credit",
                "Unused credits may expire per LuidHub terms"
            ]
        ),
        InfoSectionData(
            title: "Acceptable Use",
            bullets: [
                "No unlawful use",
                "No unauthorized access attempts",
                "No disruption or abuse of the service"
            ]
        ),
        InfoSectionData(
            title: "Intellectual Property",
            body: "Service content is owned by Luid Suite. You retain ownership of your content."
        ),
        InfoSectionData(
            title: "Disclaimer of Warranties",
            body: "The service is provided as-is without warranties."
        ),
        InfoSectionData(
            title: "Limitation of Liability",
            body: "We are not liable for indirect or consequential damages."
        ),
        InfoSectionData(
            title: "Account Termination",
            body: "Contact support@luidspeak.com to terminate your account."
        ),
        InfoSectionData(
            title: "Changes to Terms",
            body: "We may update these terms and adjust the last updated date."
        ),
        InfoSectionData(
            title: "Governing Law",
            body: "These terms are governed by applicable local law."
        )
    ]

    var body: some View {
        InfoScreen(
            title: "Terms of Service",
            subtitle: nil,
            lastUpdated: "January 2025",
            sections: sections
        )
    }
}

// MARK: - Cookie Policy

struct CookiePolicyView: View {
    private let sections: [InfoSectionData] = [
        InfoSectionData(
            title: "What Are Cookies?",
            body: "Cookies are small files that store preferences and session data."
        ),
        InfoSectionData(
            title: "How We Use Cookies",
            bullets: [
                "Essential cookies for authentication",
                "Functional cookies for preferences",
                "Performance cookies for service quality"
            ]
        ),
        InfoSectionData(
            title: "Cookies We Use",
            bullets: [
                "session_token: authentication",
                "refresh_token: keep you signed in",
                "csrf_token: security protection",
                "preferences: settings",
                "language: learning language"
            ]
        ),
        InfoSectionData(
            title: "Managing Cookies",
            body: "You can control cookies in your device or browser settings."
        ),
        InfoSectionData(
            title: "Local Storage",
            body: "We may store basic preferences to improve your experience."
        )
    ]

    var body: some View {
        InfoScreen(
            title: "Cookie Policy",
            subtitle: nil,
            lastUpdated: "January 2025",
            sections: sections
        )
    }
}
