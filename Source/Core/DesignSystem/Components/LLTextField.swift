//
//  LLTextField.swift
//  LanguageLuid
//
//  Design System - Text Field Component
//  Reusable text field with validation and states
//

import SwiftUI

/// Text field type variants
enum LLTextFieldType {
    case standard
    case email
    case password
    case secure
    case numeric
    case phone
    case url

    var keyboardType: UIKeyboardType {
        switch self {
        case .standard, .password, .secure:
            return .default
        case .email:
            return .emailAddress
        case .numeric:
            return .numberPad
        case .phone:
            return .phonePad
        case .url:
            return .URL
        }
    }

    var textContentType: UITextContentType? {
        switch self {
        case .email:
            return .emailAddress
        case .password:
            return .password
        case .secure:
            return .newPassword
        case .phone:
            return .telephoneNumber
        case .url:
            return .URL
        default:
            return nil
        }
    }

    var autocapitalization: TextInputAutocapitalization {
        switch self {
        case .email, .url:
            return .never
        default:
            return .sentences
        }
    }

    var isSecure: Bool {
        self == .password || self == .secure
    }
}

/// Custom text field component following the design system
struct LLTextField: View {
    // MARK: - Properties

    let label: String?
    let placeholder: String
    let type: LLTextFieldType
    let helperText: String?
    let errorMessage: String?
    let successMessage: String?
    let leadingIcon: Image?
    let trailingIcon: Image?
    let maxLength: Int?
    let isDisabled: Bool
    let onCommit: (() -> Void)?
    let onEditingChanged: ((Bool) -> Void)?

    @Binding var text: String
    @State private var isSecureVisible = false
    @State private var isFocused = false
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var fieldFocused: Bool

    // MARK: - Initializer

    init(
        _ placeholder: String,
        text: Binding<String>,
        label: String? = nil,
        type: LLTextFieldType = .standard,
        helperText: String? = nil,
        errorMessage: String? = nil,
        successMessage: String? = nil,
        leadingIcon: Image? = nil,
        trailingIcon: Image? = nil,
        maxLength: Int? = nil,
        isDisabled: Bool = false,
        onCommit: (() -> Void)? = nil,
        onEditingChanged: ((Bool) -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.label = label
        self.type = type
        self.helperText = helperText
        self.errorMessage = errorMessage
        self.successMessage = successMessage
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
        self.maxLength = maxLength
        self.isDisabled = isDisabled
        self.onCommit = onCommit
        self.onEditingChanged = onEditingChanged
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: LLSpacing.xs) {
            // Label
            if let label = label {
                Text(label)
                    .font(LLTypography.label())
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
            }

            // Input Field
            HStack(spacing: LLSpacing.sm) {
                // Leading Icon
                if let leadingIcon = leadingIcon {
                    leadingIcon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: LLSpacing.iconSM, height: LLSpacing.iconSM)
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }

                // Text Input
                if type.isSecure && !isSecureVisible {
                    SecureField(placeholder, text: $text)
                        .textFieldStyle()
                        .focused($fieldFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .textFieldStyle()
                        .keyboardType(type.keyboardType)
                        .textContentType(type.textContentType)
                        .textInputAutocapitalization(type.autocapitalization)
                        .autocorrectionDisabled(type == .email || type == .url)
                        .focused($fieldFocused)
                }

                // Trailing Icons
                HStack(spacing: LLSpacing.xs) {
                    // Status Icons
                    if let errorMessage = errorMessage, !errorMessage.isEmpty {
                        Image(systemName: "exclamationmark.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: LLSpacing.iconSM, height: LLSpacing.iconSM)
                            .foregroundColor(LLColors.destructive.color(for: colorScheme))
                    } else if let successMessage = successMessage, !successMessage.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: LLSpacing.iconSM, height: LLSpacing.iconSM)
                            .foregroundColor(LLColors.success.color(for: colorScheme))
                    }

                    // Custom Trailing Icon
                    if let trailingIcon = trailingIcon, !type.isSecure {
                        trailingIcon
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: LLSpacing.iconSM, height: LLSpacing.iconSM)
                            .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    }

                    // Password Toggle
                    if type.isSecure {
                        Button(action: { isSecureVisible.toggle() }) {
                            Image(systemName: isSecureVisible ? "eye.slash.fill" : "eye.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: LLSpacing.iconSM, height: LLSpacing.iconSM)
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal, LLSpacing.inputPaddingHorizontal)
            .frame(height: LLSpacing.inputHeight)
            .background(
                RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                    .fill(LLColors.background.color(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LLSpacing.radiusMD)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
            .opacity(isDisabled ? 0.5 : 1.0)
            .disabled(isDisabled)
            .onChange(of: fieldFocused) { oldValue, newValue in
                isFocused = newValue
                onEditingChanged?(newValue)
            }
            .onChange(of: text) { oldValue, newValue in
                if let maxLength = maxLength, newValue.count > maxLength {
                    text = String(newValue.prefix(maxLength))
                }
            }
            .onSubmit {
                onCommit?()
            }

            // Helper/Error/Success Text
            if let errorMessage = errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(LLTypography.captionSmall())
                    .foregroundColor(LLColors.destructive.color(for: colorScheme))
            } else if let successMessage = successMessage, !successMessage.isEmpty {
                Text(successMessage)
                    .font(LLTypography.captionSmall())
                    .foregroundColor(LLColors.success.color(for: colorScheme))
            } else if let helperText = helperText {
                Text(helperText)
                    .font(LLTypography.captionSmall())
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
            }

            // Character Count
            if let maxLength = maxLength {
                HStack {
                    Spacer()
                    Text("\(text.count)/\(maxLength)")
                        .font(LLTypography.captionSmall())
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var borderColor: Color {
        if let errorMessage = errorMessage, !errorMessage.isEmpty {
            return LLColors.destructive.color(for: colorScheme)
        } else if let successMessage = successMessage, !successMessage.isEmpty {
            return LLColors.success.color(for: colorScheme)
        } else if isFocused {
            return LLColors.ring.color(for: colorScheme)
        } else {
            return LLColors.input.color(for: colorScheme)
        }
    }

    private var borderWidth: CGFloat {
        isFocused ? 2 : 1
    }
}

// MARK: - Text Field Style

private extension TextField {
    func textFieldStyle() -> some View {
        self
            .font(LLTypography.body())
            .foregroundColor(LLColors.foreground.adaptive)
    }
}

private extension SecureField {
    func textFieldStyle() -> some View {
        self
            .font(LLTypography.body())
            .foregroundColor(LLColors.foreground.adaptive)
    }
}

// MARK: - Text Field Validation

extension LLTextField {
    /// Validate email format
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    /// Validate password strength
    static func passwordStrength(_ password: String) -> (score: Int, checks: PasswordChecks) {
        let checks = PasswordChecks(
            length: password.count >= 8,
            lowercase: password.range(of: "[a-z]", options: .regularExpression) != nil,
            uppercase: password.range(of: "[A-Z]", options: .regularExpression) != nil,
            number: password.range(of: "\\d", options: .regularExpression) != nil,
            special: password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil
        )

        let score = [checks.length, checks.lowercase, checks.uppercase, checks.number, checks.special]
            .filter { $0 }.count

        return (score, checks)
    }
}

struct PasswordChecks {
    let length: Bool
    let lowercase: Bool
    let uppercase: Bool
    let number: Bool
    let special: Bool
}

// MARK: - Password Strength Indicator

struct LLPasswordStrengthIndicator: View {
    let password: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let (score, checks) = LLTextField.passwordStrength(password)

        if !password.isEmpty {
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                // Strength Bar
                HStack(spacing: LLSpacing.xs) {
                    ForEach(0..<5, id: \.self) { index in
                        RoundedRectangle(cornerRadius: LLSpacing.radiusXS)
                            .fill(index < score ? strengthColor(score: score) : LLColors.muted.color(for: colorScheme))
                            .frame(height: 4)
                    }
                }

                // Strength Label
                Text(strengthLabel(score: score))
                    .font(LLTypography.captionSmall())
                    .foregroundColor(strengthColor(score: score))
                    .fontWeight(.medium)

                // Requirements Checklist
                VStack(alignment: .leading, spacing: LLSpacing.xs) {
                    checklistItem("At least 8 characters", isValid: checks.length)
                    checklistItem("One lowercase letter", isValid: checks.lowercase)
                    checklistItem("One uppercase letter", isValid: checks.uppercase)
                    checklistItem("One number", isValid: checks.number)
                    checklistItem("One special character", isValid: checks.special)
                }
            }
        }
    }

    private func checklistItem(_ text: String, isValid: Bool) -> some View {
        HStack(spacing: LLSpacing.xs) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 12, height: 12)
                .foregroundColor(isValid ? LLColors.success.color(for: colorScheme) : LLColors.mutedForeground.color(for: colorScheme))

            Text(text)
                .font(LLTypography.captionSmall())
                .foregroundColor(isValid ? LLColors.success.color(for: colorScheme) : LLColors.mutedForeground.color(for: colorScheme))
        }
    }

    private func strengthLabel(score: Int) -> String {
        switch score {
        case 0...1: return "Very Weak"
        case 2: return "Weak"
        case 3: return "Fair"
        case 4: return "Good"
        case 5: return "Strong"
        default: return ""
        }
    }

    private func strengthColor(score: Int) -> Color {
        switch score {
        case 0...1: return LLColors.destructive.color(for: colorScheme)
        case 2...3: return LLColors.warning.color(for: colorScheme)
        case 4: return LLColors.primary.color(for: colorScheme)
        case 5: return LLColors.success.color(for: colorScheme)
        default: return LLColors.mutedForeground.color(for: colorScheme)
        }
    }
}

// MARK: - Preview

#Preview("Text Fields") {
    ScrollView {
        VStack(spacing: LLSpacing.lg) {
            // Standard
            LLTextField(
                "Enter your name",
                text: .constant(""),
                label: "Name"
            )

            // Email
            LLTextField(
                "Enter your email",
                text: .constant(""),
                label: "Email",
                type: .email,
                leadingIcon: Image(systemName: "envelope")
            )

            // Password
            LLTextField(
                "Enter password",
                text: .constant(""),
                label: "Password",
                type: .password
            )

            // With Error
            LLTextField(
                "Enter email",
                text: .constant("invalid"),
                label: "Email",
                type: .email,
                errorMessage: "Please enter a valid email address"
            )

            // With Success
            LLTextField(
                "Enter email",
                text: .constant("user@example.com"),
                label: "Email",
                type: .email,
                successMessage: "Email is valid"
            )

            // With Helper Text
            LLTextField(
                "Choose a username",
                text: .constant(""),
                label: "Username",
                helperText: "Username must be 3-20 characters",
                maxLength: 20
            )

            // Password Strength
            VStack(alignment: .leading, spacing: LLSpacing.sm) {
                LLTextField(
                    "Create password",
                    text: .constant("MyP@ssw0rd"),
                    label: "Password",
                    type: .secure
                )
                LLPasswordStrengthIndicator(password: "MyP@ssw0rd")
            }
        }
        .padding()
    }
}
