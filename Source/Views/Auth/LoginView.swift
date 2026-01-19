//
//  LoginView.swift
//  LanguageLuid
//
//  Login screen with email/password authentication
//  Includes social login options, remember me, and forgot password
//

import SwiftUI

/// Login view for user authentication
struct LoginView: View {
    // MARK: - Properties

    @ObservedObject var authViewModel: AuthViewModel

    let onForgotPassword: () -> Void
    let onNeedVerification: (String) -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = true
    @State private var showPassword = false

    @Environment(\.colorScheme) var colorScheme
    @FocusState private var focusedField: Field?

    // MARK: - Field Focus

    private enum Field {
        case email
        case password
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: LLSpacing.lg) {
            // Login Form
            VStack(spacing: LLSpacing.md) {
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
                LLTextField(
                    "Password",
                    text: $password,
                    label: "Password",
                    type: .password,
                    errorMessage: authViewModel.validationErrors["password"],
                    isDisabled: authViewModel.isLoading
                ) {
                    handleLogin()
                }
                .focused($focusedField, equals: .password)
                .submitLabel(.go)
                .onChange(of: password) { _, _ in
                    authViewModel.clearFieldError("password")
                }

                // Remember Me & Forgot Password
                HStack {
                    // Remember Me Toggle
                    Button(action: { rememberMe.toggle() }) {
                        HStack(spacing: LLSpacing.xs) {
                            Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(
                                    rememberMe
                                        ? LLColors.primary.color(for: colorScheme)
                                        : LLColors.mutedForeground.color(for: colorScheme)
                                )

                            Text("Remember me")
                                .font(LLTypography.bodySmall())
                                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()

                    // Forgot Password Link
                    Button(action: onForgotPassword) {
                        Text("Forgot password?")
                            .font(LLTypography.bodySmall())
                            .foregroundColor(LLColors.primary.color(for: colorScheme))
                            .underline()
                    }
                    .buttonStyle(PlainButtonStyle())
                }
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

            // Login Button
            LLButton(
                "Login",
                style: .primary,
                size: .lg,
                isLoading: authViewModel.isLoading,
                isDisabled: !isFormValid,
                fullWidth: true
            ) {
                handleLogin()
            }
            .padding(.top, LLSpacing.sm)

            // Divider
            HStack(spacing: LLSpacing.md) {
                Rectangle()
                    .fill(LLColors.border.color(for: colorScheme))
                    .frame(height: 1)

                Text("or continue with")
                    .font(LLTypography.caption())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                Rectangle()
                    .fill(LLColors.border.color(for: colorScheme))
                    .frame(height: 1)
            }
            .padding(.vertical, LLSpacing.sm)

            // Social Login Buttons
            VStack(spacing: LLSpacing.sm) {
                // Google Login
                LLButton(
                    "Continue with Google",
                    icon: Image(systemName: "g.circle.fill"),
                    style: .outline,
                    size: .lg,
                    fullWidth: true
                ) {
                    handleGoogleLogin()
                }

                // Apple Login
                LLButton(
                    "Continue with Apple",
                    icon: Image(systemName: "apple.logo"),
                    style: .outline,
                    size: .lg,
                    fullWidth: true
                ) {
                    handleAppleLogin()
                }
            }

            // Terms & Privacy
            VStack(spacing: LLSpacing.xs) {
                Text("By continuing, you agree to our")
                    .font(LLTypography.captionSmall())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                HStack(spacing: 4) {
                    Button("Terms of Service") {
                        // Open terms
                    }
                    .font(LLTypography.captionSmall())
                    .foregroundColor(LLColors.primary.color(for: colorScheme))

                    Text("and")
                        .font(LLTypography.captionSmall())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                    Button("Privacy Policy") {
                        // Open privacy policy
                    }
                    .font(LLTypography.captionSmall())
                    .foregroundColor(LLColors.primary.color(for: colorScheme))
                }
            }
            .multilineTextAlignment(.center)
            .padding(.top, LLSpacing.sm)
        }
        .onAppear {
            focusedField = .email
        }
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }

    // MARK: - Actions

    private func handleLogin() {
        focusedField = nil // Dismiss keyboard

        Task {
            let success = await authViewModel.login(email: email, password: password)

            if success {
                // Login successful - handled by parent view
                print("Login successful")
            } else {
                // Check if email verification is needed
                if let error = authViewModel.errorMessage,
                   error.contains("verify") || error.contains("verification") {
                    onNeedVerification(email)
                }
            }
        }
    }

    private func handleGoogleLogin() {
        // TODO: Implement Google Sign-In
        print("Google login tapped - implementation needed")
    }

    private func handleAppleLogin() {
        // TODO: Implement Sign in with Apple
        print("Apple login tapped - implementation needed")
    }
}

// MARK: - Preview

#Preview("Login View") {
    ScrollView {
        LoginView(
            authViewModel: AuthViewModel(),
            onForgotPassword: {},
            onNeedVerification: { _ in }
        )
        .padding()
    }
}

#Preview("Login View - With Error") {
    ScrollView {
        LoginView(
            authViewModel: AuthViewModel.mockWithError("Invalid email or password. Please try again."),
            onForgotPassword: {},
            onNeedVerification: { _ in }
        )
        .padding()
    }
}

#Preview("Login View - Loading") {
    ScrollView {
        LoginView(
            authViewModel: AuthViewModel.mockLoading(),
            onForgotPassword: {},
            onNeedVerification: { _ in }
        )
        .padding()
    }
}
