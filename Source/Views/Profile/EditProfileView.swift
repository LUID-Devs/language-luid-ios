//
//  EditProfileView.swift
//  LanguageLuid
//
//  Edit user profile information
//  Native iOS form with validation
//

import SwiftUI

/// Edit profile view for updating user information
struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var nativeLanguage: String = ""
    @State private var isLoading = false
    @State private var showingSuccessAlert = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            // Profile Photo Section
            Section {
                HStack {
                    Spacer()

                    VStack(spacing: LLSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(LLColors.primary.color(for: colorScheme))
                                .frame(width: LLSpacing.avatarXXL, height: LLSpacing.avatarXXL)

                            Text(initials)
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundColor(LLColors.primaryForeground.color(for: colorScheme))
                        }

                        Button {
                            // TODO: Implement photo upload
                        } label: {
                            Text("Change Photo")
                                .font(LLTypography.bodyMedium())
                                .foregroundColor(LLColors.primary.color(for: colorScheme))
                        }
                    }
                    .padding(.vertical, LLSpacing.md)

                    Spacer()
                }
            }
            .listRowBackground(Color.clear)

            // Personal Information
            Section {
                HStack {
                    Text("First Name")
                        .frame(width: 100, alignment: .leading)
                    TextField("John", text: $firstName)
                        .textContentType(.givenName)
                        .autocapitalization(.words)
                }

                HStack {
                    Text("Last Name")
                        .frame(width: 100, alignment: .leading)
                    TextField("Doe", text: $lastName)
                        .textContentType(.familyName)
                        .autocapitalization(.words)
                }

                HStack {
                    Text("Username")
                        .frame(width: 100, alignment: .leading)
                    TextField("johndoe", text: $username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                }
            } header: {
                Text("Personal Information")
            } footer: {
                Text("Your name will be displayed on your profile and in leaderboards.")
            }

            // Contact Information
            Section {
                HStack {
                    Text("Email")
                        .frame(width: 100, alignment: .leading)
                    Text(email)
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
            } header: {
                Text("Contact Information")
            } footer: {
                Text("Email address cannot be changed. Contact support if you need to update it.")
            }

            // Language Preferences
            Section {
                NavigationLink {
                    NativeLanguagePickerView(selectedLanguage: $nativeLanguage)
                } label: {
                    HStack {
                        Text("Native Language")
                            .frame(width: 140, alignment: .leading)

                        Spacer()

                        Text(languageName(for: nativeLanguage))
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                }
            } header: {
                Text("Language Preferences")
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isLoading)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .disabled(isLoading)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveProfile()
                }
                .disabled(isLoading || !hasChanges)
                .fontWeight(.semibold)
            }
        }
        .overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding(LLSpacing.xl)
                        .background(
                            RoundedRectangle(cornerRadius: LLSpacing.radiusLG)
                                .fill(LLColors.card.color(for: colorScheme))
                        )
                }
            }
        }
        .alert("Profile Updated", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your profile has been successfully updated.")
        }
        .alert("Error", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear {
            loadUserData()
        }
    }

    // MARK: - Helper Methods

    private var initials: String {
        let first = firstName.isEmpty ? "" : String(firstName.prefix(1))
        let last = lastName.isEmpty ? "" : String(lastName.prefix(1))
        return "\(first)\(last)".uppercased()
    }

    private var hasChanges: Bool {
        guard let user = authViewModel.currentUser else { return false }

        return firstName != (user.firstName ?? "") ||
               lastName != (user.lastName ?? "") ||
               username != (user.username ?? "") ||
               nativeLanguage != (user.nativeLanguage ?? "")
    }

    private func loadUserData() {
        guard let user = authViewModel.currentUser else { return }

        firstName = user.firstName ?? ""
        lastName = user.lastName ?? ""
        username = user.username ?? ""
        email = user.email
        nativeLanguage = user.nativeLanguage ?? "en-US"
    }

    private func saveProfile() {
        isLoading = true

        // TODO: Implement API call to update profile
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            showingSuccessAlert = true
        }
    }

    private func languageName(for code: String) -> String {
        let languages: [String: String] = [
            "en-US": "English (US)",
            "en-GB": "English (UK)",
            "es": "Spanish",
            "fr": "French",
            "de": "German",
            "it": "Italian",
            "pt": "Portuguese",
            "zh": "Chinese",
            "ja": "Japanese",
            "ko": "Korean"
        ]
        return languages[code] ?? code
    }
}

// MARK: - Native Language Picker

struct NativeLanguagePickerView: View {
    @Binding var selectedLanguage: String
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    private let languages = [
        ("en-US", "English (US)", "🇺🇸"),
        ("en-GB", "English (UK)", "🇬🇧"),
        ("es", "Spanish", "🇪🇸"),
        ("fr", "French", "🇫🇷"),
        ("de", "German", "🇩🇪"),
        ("it", "Italian", "🇮🇹"),
        ("pt", "Portuguese", "🇵🇹"),
        ("zh", "Chinese", "🇨🇳"),
        ("ja", "Japanese", "🇯🇵"),
        ("ko", "Korean", "🇰🇷")
    ]

    var body: some View {
        List {
            ForEach(languages, id: \.0) { code, name, flag in
                Button {
                    selectedLanguage = code
                    dismiss()
                } label: {
                    HStack {
                        Text(flag)
                            .font(.system(size: 32))
                            .frame(width: 44)

                        Text(name)
                            .font(LLTypography.body())
                            .foregroundColor(LLColors.foreground.color(for: colorScheme))

                        Spacer()

                        if selectedLanguage == code {
                            Image(systemName: "checkmark")
                                .foregroundColor(LLColors.primary.color(for: colorScheme))
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .navigationTitle("Native Language")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview("Edit Profile") {
    NavigationStack {
        EditProfileView()
            .environmentObject(AuthViewModel.mock())
    }
}
