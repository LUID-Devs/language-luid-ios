//
//  VerifyEmailView.swift
//  LanguageLuid
//
//  Email verification screen with 6-digit code input
//  Includes resend functionality with countdown timer
//

import SwiftUI

/// Email verification view
struct VerifyEmailView: View {
    // MARK: - Properties

    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    let email: String

    @State private var verificationCode: [String] = Array(repeating: "", count: 6)
    @State private var canResend = false
    @State private var resendCountdown = 60
    @State private var showSuccess = false
    @State private var timer: Timer?

    @FocusState private var focusedIndex: Int?

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

                        // Code Input
                        codeInputSection

                        // Error Message
                        if let errorMessage = authViewModel.errorMessage {
                            errorMessageView(errorMessage)
                        }

                        // Success Message
                        if let successMessage = authViewModel.successMessage {
                            successMessageView(successMessage)
                        }

                        // Verify Button
                        LLButton(
                            "Verify Email",
                            style: .primary,
                            size: .lg,
                            isLoading: authViewModel.isLoading,
                            isDisabled: !isCodeComplete,
                            fullWidth: true
                        ) {
                            handleVerification()
                        }

                        // Resend Section
                        resendSection

                        Spacer()
                    }
                    .padding(.horizontal, LLSpacing.screenPaddingHorizontal)
                    .padding(.vertical, LLSpacing.xl)
                }
            }
            .navigationTitle("Verify Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            startResendTimer()
            focusedIndex = 0
        }
        .onDisappear {
            stopResendTimer()
        }
        .overlay {
            if showSuccess {
                successAnimation
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

                Image(systemName: "envelope.badge.shield.half.filled")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(LLColors.primary.color(for: colorScheme))
            }

            // Title
            Text("Check Your Email")
                .font(LLTypography.h2())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                .multilineTextAlignment(.center)

            // Description
            VStack(spacing: LLSpacing.xs) {
                Text("We've sent a 6-digit verification code to:")
                    .font(LLTypography.body())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    .multilineTextAlignment(.center)

                Text(email)
                    .font(LLTypography.bodyMedium())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Code Input Section

    private var codeInputSection: some View {
        VStack(spacing: LLSpacing.sm) {
            Text("Enter Verification Code")
                .font(LLTypography.label())
                .foregroundColor(LLColors.foreground.color(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: LLSpacing.sm) {
                ForEach(0..<6, id: \.self) { index in
                    codeDigitField(index: index)
                }
            }
        }
    }

    // MARK: - Code Digit Field

    private func codeDigitField(index: Int) -> some View {
        TextField("", text: $verificationCode[index])
            .font(LLTypography.h3())
            .multilineTextAlignment(.center)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                    .fill(LLColors.background.color(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                    .strokeBorder(
                        focusedIndex == index
                            ? LLColors.primary.color(for: colorScheme)
                            : LLColors.input.color(for: colorScheme),
                        lineWidth: focusedIndex == index ? 2 : 1
                    )
            )
            .keyboardType(.numberPad)
            .focused($focusedIndex, equals: index)
            .onChange(of: verificationCode[index]) { oldValue, newValue in
                handleCodeInput(index: index, oldValue: oldValue, newValue: newValue)
            }
            .disabled(authViewModel.isLoading)
    }

    // MARK: - Resend Section

    private var resendSection: some View {
        VStack(spacing: LLSpacing.sm) {
            Text("Didn't receive the code?")
                .font(LLTypography.body())
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

            if canResend {
                Button(action: handleResend) {
                    Text("Resend Code")
                        .font(LLTypography.bodyMedium())
                        .foregroundColor(LLColors.primary.color(for: colorScheme))
                        .underline()
                }
                .disabled(authViewModel.isLoading)
            } else {
                Text("Resend code in \(resendCountdown)s")
                    .font(LLTypography.bodySmall())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }
        }
    }

    // MARK: - Success Animation

    private var successAnimation: some View {
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
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }
                .scaleEffect(showSuccess ? 1.0 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showSuccess)

                Text("Email Verified!")
                    .font(LLTypography.h3())
                    .foregroundColor(.white)
            }
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

    private var isCodeComplete: Bool {
        verificationCode.allSatisfy { !$0.isEmpty }
    }

    private var fullCode: String {
        verificationCode.joined()
    }

    // MARK: - Actions

    private func handleCodeInput(index: Int, oldValue: String, newValue: String) {
        // Only allow single digit
        if newValue.count > 1 {
            verificationCode[index] = String(newValue.suffix(1))
        }

        // Move to next field if digit entered
        if !newValue.isEmpty && oldValue.isEmpty {
            if index < 5 {
                focusedIndex = index + 1
            } else {
                focusedIndex = nil
                // Auto-verify when all digits entered
                if isCodeComplete {
                    handleVerification()
                }
            }
        }

        // Move to previous field if digit deleted
        if newValue.isEmpty && !oldValue.isEmpty && index > 0 {
            focusedIndex = index - 1
        }

        // Clear error when user types
        authViewModel.clearError()
    }

    private func handleVerification() {
        guard isCodeComplete else { return }

        Task {
            let success = await authViewModel.verifyEmail(email: email, code: fullCode)

            if success {
                // Show success animation
                withAnimation {
                    showSuccess = true
                }

                // Dismiss after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }

    private func handleResend() {
        Task {
            let success = await authViewModel.resendVerificationCode(email: email)

            if success {
                // Reset countdown
                canResend = false
                resendCountdown = 60
                startResendTimer()

                // Clear code fields
                verificationCode = Array(repeating: "", count: 6)
                focusedIndex = 0
            }
        }
    }

    private func startResendTimer() {
        canResend = false
        resendCountdown = 60

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if resendCountdown > 0 {
                resendCountdown -= 1
            } else {
                canResend = true
                stopResendTimer()
            }
        }
    }

    private func stopResendTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Preview

#Preview("Verify Email View") {
    VerifyEmailView(
        authViewModel: AuthViewModel(),
        email: "user@example.com"
    )
}

#Preview("Verify Email View - With Error") {
    VerifyEmailView(
        authViewModel: AuthViewModel.mockWithError("Invalid verification code. Please try again."),
        email: "user@example.com"
    )
}
