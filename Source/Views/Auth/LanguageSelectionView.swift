//
//  LanguageSelectionView.swift
//  LanguageLuid
//
//  Language picker component with search functionality
//  Displays languages with native names and flag icons
//

import SwiftUI

/// Language selection view with search and filtering
struct LanguageSelectionView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    let title: String
    @Binding var selectedLanguage: String
    let excludeLanguage: String?

    @State private var searchText = ""
    @FocusState private var searchFocused: Bool

    // MARK: - Language Data

    private let languages: [SelectableLanguage] = [
        SelectableLanguage(code: "ar", name: "Arabic", nativeName: "العربية", flag: "🇸🇦"),
        SelectableLanguage(code: "zh", name: "Chinese (Mandarin)", nativeName: "中文", flag: "🇨🇳"),
        SelectableLanguage(code: "nl", name: "Dutch", nativeName: "Nederlands", flag: "🇳🇱"),
        SelectableLanguage(code: "en", name: "English", nativeName: "English", flag: "🇬🇧"),
        SelectableLanguage(code: "fr", name: "French", nativeName: "Français", flag: "🇫🇷"),
        SelectableLanguage(code: "de", name: "German", nativeName: "Deutsch", flag: "🇩🇪"),
        SelectableLanguage(code: "el", name: "Greek", nativeName: "Ελληνικά", flag: "🇬🇷"),
        SelectableLanguage(code: "he", name: "Hebrew", nativeName: "עברית", flag: "🇮🇱"),
        SelectableLanguage(code: "hi", name: "Hindi", nativeName: "हिन्दी", flag: "🇮🇳"),
        SelectableLanguage(code: "id", name: "Indonesian", nativeName: "Bahasa Indonesia", flag: "🇮🇩"),
        SelectableLanguage(code: "it", name: "Italian", nativeName: "Italiano", flag: "🇮🇹"),
        SelectableLanguage(code: "ja", name: "Japanese", nativeName: "日本語", flag: "🇯🇵"),
        SelectableLanguage(code: "ko", name: "Korean", nativeName: "한국어", flag: "🇰🇷"),
        SelectableLanguage(code: "pl", name: "Polish", nativeName: "Polski", flag: "🇵🇱"),
        SelectableLanguage(code: "pt", name: "Portuguese", nativeName: "Português", flag: "🇵🇹"),
        SelectableLanguage(code: "ru", name: "Russian", nativeName: "Русский", flag: "🇷🇺"),
        SelectableLanguage(code: "es", name: "Spanish", nativeName: "Español", flag: "🇪🇸"),
        SelectableLanguage(code: "sv", name: "Swedish", nativeName: "Svenska", flag: "🇸🇪"),
        SelectableLanguage(code: "th", name: "Thai", nativeName: "ไทย", flag: "🇹🇭"),
        SelectableLanguage(code: "tr", name: "Turkish", nativeName: "Türkçe", flag: "🇹🇷"),
        SelectableLanguage(code: "uk", name: "Ukrainian", nativeName: "Українська", flag: "🇺🇦"),
        SelectableLanguage(code: "vi", name: "Vietnamese", nativeName: "Tiếng Việt", flag: "🇻🇳")
    ]

    // MARK: - Initializer

    init(
        title: String = "Select Language",
        selectedLanguage: Binding<String>,
        excludeLanguage: String? = nil
    ) {
        self.title = title
        self._selectedLanguage = selectedLanguage
        self.excludeLanguage = excludeLanguage
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                LLColors.background.color(for: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search Bar
                    searchBar

                    // Language List
                    if filteredLanguages.isEmpty {
                        emptyStateView
                    } else {
                        languageList
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !selectedLanguage.isEmpty {
                        Button("Done") {
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: LLSpacing.sm) {
            // Search Icon
            Image(systemName: "magnifyingglass")
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                .font(.system(size: 16, weight: .medium))

            // Search Field
            TextField("Search languages", text: $searchText)
                .font(LLTypography.body())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                .focused($searchFocused)
                .submitLabel(.search)

            // Clear Button
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        .font(.system(size: 16, weight: .medium))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, LLSpacing.md)
        .padding(.vertical, LLSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                .fill(LLColors.muted.color(for: colorScheme).opacity(0.3))
        )
        .padding(.horizontal, LLSpacing.screenPaddingHorizontal)
        .padding(.vertical, LLSpacing.md)
    }

    // MARK: - Language List

    private var languageList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredLanguages) { language in
                    languageRow(language)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectLanguage(language)
                        }

                    Divider()
                        .padding(.leading, 80)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Language Row

    private func languageRow(_ language: SelectableLanguage) -> some View {
        HStack(spacing: LLSpacing.md) {
            // Flag
            Text(language.flag)
                .font(.system(size: 40))
                .frame(width: 50, height: 50)

            // Language Names
            VStack(alignment: .leading, spacing: 4) {
                Text(language.name)
                    .font(LLTypography.bodyMedium())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))

                Text(language.nativeName)
                    .font(LLTypography.bodySmall())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }

            Spacer()

            // Selection Indicator
            if selectedLanguage == language.code {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(LLColors.primary.color(for: colorScheme))
                    .font(.system(size: 24))
            }
        }
        .padding(.horizontal, LLSpacing.screenPaddingHorizontal)
        .padding(.vertical, LLSpacing.md)
        .background(
            selectedLanguage == language.code
                ? LLColors.primary.color(for: colorScheme).opacity(0.05)
                : Color.clear
        )
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: LLSpacing.lg) {
            Image(systemName: "magnifyingglass")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

            VStack(spacing: LLSpacing.xs) {
                Text("No Languages Found")
                    .font(LLTypography.h4())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))

                Text("Try adjusting your search")
                    .font(LLTypography.body())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Computed Properties

    private var filteredLanguages: [SelectableLanguage] {
        var filtered = languages

        // Exclude language if specified
        if let excludeCode = excludeLanguage, !excludeCode.isEmpty {
            filtered = filtered.filter { $0.code != excludeCode }
        }

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { language in
                language.name.localizedCaseInsensitiveContains(searchText) ||
                language.nativeName.localizedCaseInsensitiveContains(searchText) ||
                language.code.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered.sorted { $0.name < $1.name }
    }

    // MARK: - Actions

    private func selectLanguage(_ language: SelectableLanguage) {
        selectedLanguage = language.code

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // Auto-dismiss after selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}

// MARK: - Language Model

struct SelectableLanguage: Identifiable, Hashable {
    let id = UUID()
    let code: String
    let name: String
    let nativeName: String
    let flag: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    static func == (lhs: SelectableLanguage, rhs: SelectableLanguage) -> Bool {
        lhs.code == rhs.code
    }
}

// MARK: - Language Selection Button Component

/// Reusable language selection button
struct LanguageSelectionButton: View {
    let label: String
    let selectedLanguageCode: String
    let isDisabled: Bool
    let errorMessage: String?
    let onTap: () -> Void

    @Environment(\.colorScheme) var colorScheme

    private let languages: [String: String] = [
        "ar": "Arabic",
        "zh": "Chinese",
        "nl": "Dutch",
        "en": "English",
        "fr": "French",
        "de": "German",
        "el": "Greek",
        "he": "Hebrew",
        "hi": "Hindi",
        "id": "Indonesian",
        "it": "Italian",
        "ja": "Japanese",
        "ko": "Korean",
        "pl": "Polish",
        "pt": "Portuguese",
        "ru": "Russian",
        "es": "Spanish",
        "sv": "Swedish",
        "th": "Thai",
        "tr": "Turkish",
        "uk": "Ukrainian",
        "vi": "Vietnamese"
    ]

    init(
        label: String,
        selectedLanguageCode: String,
        isDisabled: Bool = false,
        errorMessage: String? = nil,
        onTap: @escaping () -> Void
    ) {
        self.label = label
        self.selectedLanguageCode = selectedLanguageCode
        self.isDisabled = isDisabled
        self.errorMessage = errorMessage
        self.onTap = onTap
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LLSpacing.xs) {
            Text(label)
                .font(LLTypography.label())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            Button(action: onTap) {
                HStack {
                    if selectedLanguageCode.isEmpty {
                        Text("Select language")
                            .font(LLTypography.body())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    } else {
                        Text(languages[selectedLanguageCode] ?? selectedLanguageCode)
                            .font(LLTypography.body())
                            .foregroundColor(LLColors.foreground.color(for: colorScheme))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
                .padding(.horizontal, LLSpacing.inputPaddingHorizontal)
                .frame(height: LLSpacing.inputHeight)
                .background(
                    RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                        .fill(LLColors.background.color(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                        .strokeBorder(
                            errorMessage != nil && !errorMessage!.isEmpty
                                ? LLColors.destructive.color(for: colorScheme)
                                : LLColors.input.color(for: colorScheme),
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.5 : 1.0)

            if let error = errorMessage, !error.isEmpty {
                Text(error)
                    .font(LLTypography.captionSmall())
                    .foregroundColor(LLColors.destructive.color(for: colorScheme))
            }
        }
    }
}

// MARK: - Preview

#Preview("Language Selection") {
    LanguageSelectionView(
        title: "Select Your Native Language",
        selectedLanguage: .constant("en")
    )
}

#Preview("Language Selection - With Exclusion") {
    LanguageSelectionView(
        title: "Select Language to Learn",
        selectedLanguage: .constant(""),
        excludeLanguage: "en"
    )
}

#Preview("Language Selection - With Search") {
    struct PreviewWrapper: View {
        @State private var selected = "es"

        var body: some View {
            LanguageSelectionView(
                title: "Select Language",
                selectedLanguage: $selected
            )
        }
    }

    return PreviewWrapper()
}
