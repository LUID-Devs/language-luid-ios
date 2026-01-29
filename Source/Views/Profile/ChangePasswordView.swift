//
//  ChangePasswordView.swift
//  LanguageLuid
//
//  Change user password with validation
//  Follows iOS security best practices
//

import SwiftUI

/// Change password view with security validation
struct ChangePasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading = false
    @State private var showingSuccessAlert = false
    @State private var errorMessage: String?
    @State private var showCurrentPassword = false
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false

    @FocusState private var focusedField: Field?

    enum Field {
        case currentPassword
        case newPassword
        case confirmPassword
    }

    var body: some View {
        Form {
            // Current Password Section
            Section {
                HStack {
                    if showCurrentPassword {
                        TextField("Enter current password", text: $currentPassword)
                            .textContentType(.password)
                            .focused($focusedField, equals: .currentPassword)
                    } else {
                        SecureField("Enter current password", text: $currentPassword)
                            .textContentType(.password)
                            .focused($focusedField, equals: .currentPassword)
                    }

                    Button {
                        showCurrentPassword.toggle()
                    } label: {
                        Image(systemName: showCurrentPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                }
            } header: {
                Text("Current Password")
            } footer: {
                Text("Enter your current password to confirm your identity.")
            }

            // New Password Section
            Section {
                HStack {
                    if showNewPassword {
                        TextField("Enter new password", text: $newPassword)
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .newPassword)
                    } else {
                        SecureField("Enter new password", text: $newPassword)
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .newPassword)
                    }

                    Button {
                        showNewPassword.toggle()
                    } label: {
                        Image(systemName: showNewPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                }

                HStack {
                    if showConfirmPassword {
                        TextField("Confirm new password", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .confirmPassword)
                    } else {
                        SecureField("Confirm new password", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .confirmPassword)
                    }

                    Button {
                        showConfirmPassword.toggle()
                    } label: {
                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }
                }
            } header: {
                Text("New Password")
            } footer: {
                VStack(alignment: .leading, spacing: LLSpacing.sm) {
                    Text("Password must:")
                        .fontWeight(.medium)

                    passwordRequirement("At least 8 characters", met: newPassword.count >= 8)
                    passwordRequirement("Contains uppercase letter", met: newPassword.range(of: "[A-Z]", options: .regularExpression) != nil)
                    passwordRequirement("Contains lowercase letter", met: newPassword.range(of: "[a-z]", options: .regularExpression) != nil)
                    passwordRequirement("Contains number", met: newPassword.range(of: "[0-9]", options: .regularExpression) != nil)

                    if !confirmPassword.isEmpty && confirmPassword != newPassword {
                        HStack(spacing: LLSpacing.xs) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text("Passwords do not match")
                                .foregroundColor(.red)
                        }
                        .font(LLTypography.caption())
                    }
                }
            }

            // Password Strength Indicator
            if !newPassword.isEmpty {
                Section {
                    VStack(alignment: .leading, spacing: LLSpacing.sm) {
                        HStack {
                            Text("Password Strength:")
                                .font(LLTypography.bodyMedium())
                                .foregroundColor(LLColors.foreground.color(for: colorScheme))

                            Spacer()

                            Text(passwordStrength.description)
                                .font(LLTypography.bodyMedium())
                                .foregroundColor(passwordStrengthColor)
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: LLSpacing.radiusSM)
                                    .fill(LLColors.muted.color(for: colorScheme))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: LLSpacing.radiusSM)
                                    .fill(passwordStrengthColor)
                                    .frame(width: geometry.size.width * passwordStrengthPercentage, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.vertical, LLSpacing.xs)
                }
            }
        }
        .navigationTitle("Change Password")
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
                    changePassword()
                }
                .disabled(!isFormValid || isLoading)
                .fontWeight(.semibold)
            }

            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
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
        .alert("Password Changed", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your password has been successfully changed.")
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
    }

    // MARK: - Helper Views

    private func passwordRequirement(_ text: String, met: Bool) -> some View {
        HStack(spacing: LLSpacing.xs) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundColor(met ? .green : LLColors.mutedForeground.color(for: colorScheme))
            Text(text)
                .foregroundColor(met ? LLColors.foreground.color(for: colorScheme) : LLColors.mutedForeground.color(for: colorScheme))
        }
        .font(LLTypography.caption())
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        newPassword == confirmPassword &&
        isPasswordValid
    }

    private var isPasswordValid: Bool {
        newPassword.count >= 8 &&
        newPassword.range(of: "[A-Z]", options: .regularExpression) != nil &&
        newPassword.range(of: "[a-z]", options: .regularExpression) != nil &&
        newPassword.range(of: "[0-9]", options: .regularExpression) != nil
    }

    private var passwordStrength: PasswordStrength {
        authViewModel.checkPasswordStrength(newPassword)
    }

    private var passwordStrengthColor: Color {
        switch passwordStrength {
        case .weak:
            return .red
        case .medium:
            return .orange
        case .strong:
            return Color.green
        case .veryStrong:
            return Color.blue
        }
    }

    private var passwordStrengthPercentage: CGFloat {
        switch passwordStrength {
        case .weak:
            return 0.25
        case .medium:
            return 0.5
        case .strong:
            return 0.75
        case .veryStrong:
            return 1.0
        }
    }

    // MARK: - Methods

    private func changePassword() {
        guard isFormValid else { return }

        isLoading = true
        focusedField = nil

        // TODO: Implement API call to change password
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false

            // Simulate validation
            if currentPassword == "wrongpassword" {
                errorMessage = "Current password is incorrect."
            } else {
                showingSuccessAlert = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Change Password") {
    NavigationStack {
        ChangePasswordView()
            .environmentObject(AuthViewModel.mock())
    }
}
