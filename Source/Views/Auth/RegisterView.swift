//
//  RegisterView.swift
//  LanguageLuid
//
//  Registration screen with comprehensive form validation
//  Includes language selection, password strength indicator, and terms acceptance
//

import SwiftUI

/// Registration view for new user account creation
struct RegisterView: View {
    // MARK: - Properties

    @ObservedObject var authViewModel: AuthViewModel

    let onSuccess: (String) -> Void

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var nativeLanguage = ""
    @State private var targetLanguage = ""
    @State private var acceptedTerms = false
    @State private var showNativeLanguagePicker = false
    @State private var showTargetLanguagePicker = false

    @Environment(\.colorScheme) var colorScheme
    @FocusState private var focusedField: Field?

    // MARK: - Field Focus

    private enum Field {
        case firstName
        case lastName
        case email
        case password
        case confirmPassword
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: LLSpacing.lg) {
            // Registration Form
            VStack(spacing: LLSpacing.md) {
                // Name Fields
                HStack(spacing: LLSpacing.sm) {
                    // First Name
                    LLTextField(
                        "First name",
                        text: $firstName,
                        label: "First Name",
                        errorMessage: authViewModel.validationErrors["firstName"],
                        isDisabled: authViewModel.isLoading
                    ) {
                        focusedField = .lastName
                    }
                    .focused($focusedField, equals: .firstName)
                    .submitLabel(.next)
                    .onChange(of: firstName) { _, _ in
                        authViewModel.clearFieldError("firstName")
                    }

                    // Last Name
                    LLTextField(
                        "Last name",
                        text: $lastName,
                        label: "Last Name",
                        errorMessage: authViewModel.validationErrors["lastName"],
                        isDisabled: authViewModel.isLoading
                    ) {
                        focusedField = .email
                    }
                    .focused($focusedField, equals: .lastName)
                    .submitLabel(.next)
                    .onChange(of: lastName) { _, _ in
                        authViewModel.clearFieldError("lastName")
                    }
                }

                // Email Field
                LLTextField(
                    "Email address",
                    text: $email,
                    label: "Email",
                    type: .email,
                    errorMessage: authViewModel.validationErrors["email"],
                    leadingIcon: Image(systemName: "envelope"),
                    isDisabled: authViewModel.isLoading
                ) {
                    focusedField = .password
                }
                .focused($focusedField, equals: .email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .onChange(of: email) { _, _ in
                    authViewModel.clearFieldError("email")
                }

                // Password Field
                VStack(alignment: .leading, spacing: LLSpacing.sm) {
                    LLTextField(
                        "Create password",
                        text: $password,
                        label: "Password",
                        type: .secure,
                        errorMessage: authViewModel.validationErrors["password"],
                        isDisabled: authViewModel.isLoading
                    ) {
                        focusedField = .confirmPassword
                    }
                    .focused($focusedField, equals: .password)
                    .submitLabel(.next)
                    .onChange(of: password) { _, newValue in
                        authViewModel.clearFieldError("password")
                        _ = authViewModel.checkPasswordStrength(newValue)
                    }

                    // Password Strength Indicator
                    if !password.isEmpty {
                        LLPasswordStrengthIndicator(password: password)
                    }
                }

                // Confirm Password Field
                LLTextField(
                    "Confirm password",
                    text: $confirmPassword,
                    label: "Confirm Password",
                    type: .secure,
                    errorMessage: confirmPasswordError,
                    successMessage: confirmPasswordSuccess,
                    isDisabled: authViewModel.isLoading
                ) {
                    focusedField = nil
                }
                .focused($focusedField, equals: .confirmPassword)
                .submitLabel(.done)

                // Language Selection
                VStack(spacing: LLSpacing.sm) {
                    // Native Language
                    languageButton(
                        label: "Native Language",
                        selectedLanguage: nativeLanguage,
                        errorMessage: authViewModel.validationErrors["nativeLanguage"]
                    )

                    // Target Language
                    languageButton(
                        label: "Language to Learn",
                        selectedLanguage: targetLanguage,
                        errorMessage: authViewModel.validationErrors["targetLanguage"]
                    )
                }

                // Terms & Conditions
                Button(action: { acceptedTerms.toggle() }) {
                    HStack(alignment: .top, spacing: LLSpacing.sm) {
                        Image(systemName: acceptedTerms ? "checkmark.square.fill" : "square")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(
                                acceptedTerms
                                    ? LLColors.primary.color(for: colorScheme)
                                    : LLColors.mutedForeground.color(for: colorScheme)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("I agree to the Terms & Conditions")
                                .font(LLTypography.bodySmall())
                                .foregroundColor(LLColors.foreground.color(for: colorScheme))

                            HStack(spacing: 4) {
                                Button("Terms of Service") {
                                    // Open terms
                                }
                                .font(LLTypography.captionSmall())
                                .foregroundColor(LLColors.primary.color(for: colorScheme))
                                .underline()

                                Text("and")
                                    .font(LLTypography.captionSmall())
                                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                                Button("Privacy Policy") {
                                    // Open privacy policy
                                }
                                .font(LLTypography.captionSmall())
                                .foregroundColor(LLColors.primary.color(for: colorScheme))
                                .underline()
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Error Message
            if let errorMessage = authViewModel.errorMessage {
                HStack(spacing: LLSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(LLColors.destructive.color(for: colorScheme))

                    Text(errorMessage)
                        .font(LLTypography.bodySmall())
                        .foregroundColor(LLColors.destructive.color(for: colorScheme))
                        .multilineTextAlignment(.leading)
                }
                .padding(LLSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                        .fill(LLColors.destructive.color(for: colorScheme).opacity(0.1))
                )
                .transition(.scale.combined(with: .opacity))
            }

            // Register Button
            LLButton(
                "Create Account",
                style: .primary,
                size: .lg,
                isLoading: authViewModel.isLoading,
                isDisabled: !isFormValid,
                fullWidth: true
            ) {
                handleRegister()
            }
            .padding(.top, LLSpacing.sm)
        }
        .sheet(isPresented: $showNativeLanguagePicker) {
            LanguageSelectionView(
                title: "Select Your Native Language",
                selectedLanguage: $nativeLanguage,
                excludeLanguage: targetLanguage
            )
        }
        .sheet(isPresented: $showTargetLanguagePicker) {
            LanguageSelectionView(
                title: "Select Language to Learn",
                selectedLanguage: $targetLanguage,
                excludeLanguage: nativeLanguage
            )
        }
        .onAppear {
            focusedField = .firstName
        }
    }

    // MARK: - Language Button

    private func languageButton(
        label: String,
        selectedLanguage: String,
        errorMessage: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: LLSpacing.xs) {
            Text(label)
                .font(LLTypography.label())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))

            Button(action: {
                if label.contains("Native") {
                    showNativeLanguagePicker = true
                } else {
                    showTargetLanguagePicker = true
                }
            }) {
                HStack {
                    if selectedLanguage.isEmpty {
                        Text("Select language")
                            .font(LLTypography.body())
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    } else {
                        Text(getLanguageName(selectedLanguage))
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

            if let error = errorMessage, !error.isEmpty {
                Text(error)
                    .font(LLTypography.captionSmall())
                    .foregroundColor(LLColors.destructive.color(for: colorScheme))
            }
        }
    }

    // MARK: - Computed Properties

    private var confirmPasswordError: String? {
        if !confirmPassword.isEmpty && confirmPassword != password {
            return "Passwords do not match"
        }
        return nil
    }

    private var confirmPasswordSuccess: String? {
        if !confirmPassword.isEmpty && confirmPassword == password && password.count >= 8 {
            return "Passwords match"
        }
        return nil
    }

    private var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        !nativeLanguage.isEmpty &&
        !targetLanguage.isEmpty &&
        acceptedTerms
    }

    // MARK: - Actions

    private func handleRegister() {
        focusedField = nil // Dismiss keyboard

        Task {
            let response = await authViewModel.register(
                firstName: firstName,
                lastName: lastName,
                email: email,
                password: password,
                nativeLanguage: nativeLanguage,
                targetLanguage: targetLanguage
            )

            if let response = response {
                // Registration successful
                if response.tokens == nil {
                    // Email verification required
                    onSuccess(email)
                }
                // Otherwise auto-logged in, handled by AuthViewModel
            }
        }
    }

    private func getLanguageName(_ code: String) -> String {
        let languages: [String: String] = [
            "en": "English",
            "es": "Spanish",
            "fr": "French",
            "de": "German",
            "it": "Italian",
            "pt": "Portuguese",
            "ja": "Japanese",
            "ko": "Korean",
            "zh": "Chinese",
            "ar": "Arabic",
            "ru": "Russian",
            "hi": "Hindi"
        ]
        return languages[code] ?? code
    }
}

// MARK: - Preview

#Preview("Register View") {
    ScrollView {
        RegisterView(
            authViewModel: AuthViewModel(),
            onSuccess: { _ in }
        )
        .padding()
    }
}

#Preview("Register View - With Errors") {
    ScrollView {
        RegisterView(
            authViewModel: AuthViewModel.mockWithError("This email is already registered."),
            onSuccess: { _ in }
        )
        .padding()
    }
}
