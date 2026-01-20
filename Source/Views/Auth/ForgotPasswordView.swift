//
//  ForgotPasswordView.swift
//  LanguageLuid
//
//  Password reset flow with email verification
//  Two-step process: Request code → Reset password
//

import SwiftUI

/// Forgot password view with multi-step flow
struct ForgotPasswordView: View {
    // MARK: - Properties

    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var currentStep: ResetStep = .requestCode
    @State private var email = ""
    @State private var resetCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showResetSuccess = false

    @FocusState private var focusedField: Field?

    // MARK: - Reset Steps

    private enum ResetStep {
        case requestCode
        case resetPassword
    }

    // MARK: - Field Focus

    private enum Field {
        case email
        case code
        case newPassword
        case confirmPassword
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ZStack {
                LLColors.background.color(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: LLSpacing.xl) {
                        // Header
                        headerSection

                        // Content based on step
                        Group {
                            switch currentStep {
                            case .requestCode:
                                requestCodeStep
                            case .resetPassword:
                                resetPasswordStep
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: currentStep)

                        Spacer()
                    }
                    .padding(.horizontal, LLSpacing.screenPaddingHorizontal)
                    .padding(.vertical, LLSpacing.xl)
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(currentStep == .requestCode ? "Cancel" : "Back") {
                        if currentStep == .requestCode {
                            dismiss()
                        } else {
                            withAnimation {
                                currentStep = .requestCode
                            }
                        }
                    }
                }
            }
        }
        .overlay {
            if showResetSuccess {
                resetSuccessOverlay
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: LLSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(LLColors.primary.color(for: colorScheme).opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: currentStep == .requestCode ? "lock.rotation" : "key.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(LLColors.primary.color(for: colorScheme))
            }

            // Title & Description
            VStack(spacing: LLSpacing.xs) {
                Text(currentStep == .requestCode ? "Forgot Password?" : "Create New Password")
                    .font(LLTypography.h2())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
                    .multilineTextAlignment(.center)

                Text(currentStep == .requestCode
                     ? "Enter your email address and we'll send you a code to reset your password."
                     : "Enter the code we sent to your email and create a new password.")
                    .font(LLTypography.body())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Request Code Step

    private var requestCodeStep: some View {
        VStack(spacing: LLSpacing.lg) {
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
                handleRequestCode()
            }
            .focused($focusedField, equals: .email)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.send)
            .onChange(of: email) { _, _ in
                authViewModel.clearFieldError("email")
            }

            // Error Message
            if let errorMessage = authViewModel.errorMessage {
                errorMessageView(errorMessage)
            }

            // Success Message
            if let successMessage = authViewModel.successMessage {
                successMessageView(successMessage)
            }

            // Send Code Button
            LLButton(
                "Send Reset Code",
                style: .primary,
                size: .lg,
                isLoading: authViewModel.isLoading,
                isDisabled: email.isEmpty,
                fullWidth: true
            ) {
                handleRequestCode()
            }

            // Help Text
            VStack(spacing: LLSpacing.xs) {
                Text("Remember your password?")
                    .font(LLTypography.body())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                Button("Back to Login") {
                    dismiss()
                }
                .font(LLTypography.bodyMedium())
                .foregroundColor(LLColors.primary.color(for: colorScheme))
            }
            .padding(.top, LLSpacing.sm)
        }
        .onAppear {
            focusedField = .email
        }
    }

    // MARK: - Reset Password Step

    private var resetPasswordStep: some View {
        VStack(spacing: LLSpacing.lg) {
            // Email Display
            VStack(alignment: .leading, spacing: LLSpacing.xs) {
                Text("Sending code to:")
                    .font(LLTypography.caption())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                Text(email)
                    .font(LLTypography.bodyMedium())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(LLSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                    .fill(LLColors.muted.color(for: colorScheme).opacity(0.3))
            )

            // Reset Code Field
            LLTextField(
                "Enter 6-digit code",
                text: $resetCode,
                label: "Reset Code",
                type: .numeric,
                errorMessage: authViewModel.validationErrors["code"],
                leadingIcon: Image(systemName: "number"),
                maxLength: 6,
                isDisabled: authViewModel.isLoading
            ) {
                focusedField = .newPassword
            }
            .focused($focusedField, equals: .code)
            .submitLabel(.next)
            .onChange(of: resetCode) { _, _ in
                authViewModel.clearFieldError("code")
            }

            // New Password Field
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                LLTextField(
                    "Create new password",
                    text: $newPassword,
                    label: "New Password",
                    type: .secure,
                    errorMessage: authViewModel.validationErrors["password"],
                    isDisabled: authViewModel.isLoading
                ) {
                    focusedField = .confirmPassword
                }
                .focused($focusedField, equals: .newPassword)
                .submitLabel(.next)
                .onChange(of: newPassword) { _, newValue in
                    authViewModel.clearFieldError("password")
                    _ = authViewModel.checkPasswordStrength(newValue)
                }

                // Password Strength Indicator
                if !newPassword.isEmpty {
                    LLPasswordStrengthIndicator(password: newPassword)
                }
            }

            // Confirm Password Field
            LLTextField(
                "Confirm new password",
                text: $confirmPassword,
                label: "Confirm Password",
                type: .secure,
                errorMessage: confirmPasswordError,
                successMessage: confirmPasswordSuccess,
                isDisabled: authViewModel.isLoading
            ) {
                handleResetPassword()
            }
            .focused($focusedField, equals: .confirmPassword)
            .submitLabel(.done)

            // Error Message
            if let errorMessage = authViewModel.errorMessage {
                errorMessageView(errorMessage)
            }

            // Reset Password Button
            LLButton(
                "Reset Password",
                style: .primary,
                size: .lg,
                isLoading: authViewModel.isLoading,
                isDisabled: !isResetFormValid,
                fullWidth: true
            ) {
                handleResetPassword()
            }
            .padding(.top, LLSpacing.sm)

            // Resend Code
            Button(action: handleResendCode) {
                Text("Didn't receive code? Resend")
                    .font(LLTypography.bodySmall())
                    .foregroundColor(LLColors.primary.color(for: colorScheme))
                    .underline()
            }
            .disabled(authViewModel.isLoading)
        }
        .onAppear {
            focusedField = .code
        }
    }

    // MARK: - Reset Success Overlay

    private var resetSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: LLSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(LLColors.success.color(for: colorScheme))
                        .frame(width: 100, height: 100)
                        .shadow(
                            color: LLColors.success.color(for: colorScheme).opacity(0.3),
                            radius: 20,
                            y: 10
                        )

                    Image(systemName: "checkmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .foregroundColor(LLColors.successForeground.color(for: colorScheme))
                        .fontWeight(.bold)
                }
                .scaleEffect(showResetSuccess ? 1.0 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showResetSuccess)

                VStack(spacing: LLSpacing.sm) {
                    Text("Password Reset!")
                        .font(LLTypography.h3())
                        .foregroundColor(LLColors.primaryForeground.color(for: colorScheme))

                    Text("You can now login with your new password")
                        .font(LLTypography.body())
                        .foregroundColor(LLColors.primaryForeground.color(for: colorScheme).opacity(0.85))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, LLSpacing.xl)
        }
    }

    // MARK: - Error Message View

    private func errorMessageView(_ message: String) -> some View {
        HStack(spacing: LLSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(LLColors.destructive.color(for: colorScheme))

            Text(message)
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

    // MARK: - Success Message View

    private func successMessageView(_ message: String) -> some View {
        HStack(spacing: LLSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(LLColors.success.color(for: colorScheme))

            Text(message)
                .font(LLTypography.bodySmall())
                .foregroundColor(LLColors.success.color(for: colorScheme))
                .multilineTextAlignment(.leading)
        }
        .padding(LLSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                .fill(LLColors.success.color(for: colorScheme).opacity(0.1))
        )
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Computed Properties

    private var confirmPasswordError: String? {
        if !confirmPassword.isEmpty && confirmPassword != newPassword {
            return "Passwords do not match"
        }
        return nil
    }

    private var confirmPasswordSuccess: String? {
        if !confirmPassword.isEmpty && confirmPassword == newPassword && newPassword.count >= 8 {
            return "Passwords match"
        }
        return nil
    }

    private var isResetFormValid: Bool {
        !resetCode.isEmpty &&
        resetCode.count == 6 &&
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        newPassword == confirmPassword
    }

    // MARK: - Actions

    private func handleRequestCode() {
        focusedField = nil

        Task {
            let success = await authViewModel.forgotPassword(email: email)

            if success {
                // Move to next step
                withAnimation {
                    currentStep = .resetPassword
                }
            }
        }
    }

    private func handleResetPassword() {
        focusedField = nil

        Task {
            let success = await authViewModel.resetPassword(
                email: email,
                code: resetCode,
                newPassword: newPassword
            )

            if success {
                // Show success animation
                withAnimation {
                    showResetSuccess = true
                }

                // Dismiss after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    dismiss()
                }
            }
        }
    }

    private func handleResendCode() {
        Task {
            _ = await authViewModel.forgotPassword(email: email)
        }
    }
}

// MARK: - Preview

#Preview("Forgot Password - Request Code") {
    ForgotPasswordView(authViewModel: AuthViewModel())
}

#Preview("Forgot Password - With Error") {
    ForgotPasswordView(
        authViewModel: AuthViewModel.mockWithError("Email address not found.")
    )
}
