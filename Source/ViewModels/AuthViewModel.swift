//
//  AuthViewModel.swift
//  LanguageLuid
//
//  Authentication ViewModel managing auth state and user interactions
//  Integrates with AuthService, KeychainManager, and handles all auth flows
//

import Foundation
import Combine

/// Password strength levels for visual feedback
enum PasswordStrength {
    case weak
    case medium
    case strong
    case veryStrong

    var description: String {
        switch self {
        case .weak: return "Weak"
        case .medium: return "Medium"
        case .strong: return "Strong"
        case .veryStrong: return "Very Strong"
        }
    }

    var color: String {
        switch self {
        case .weak: return "red"
        case .medium: return "orange"
        case .strong: return "green"
        case .veryStrong: return "blue"
        }
    }
}

/// Authentication ViewModel managing all authentication state and operations
/// - Note: Marked as @MainActor to ensure all UI updates happen on the main thread
@MainActor
class AuthViewModel: ObservableObject {

    // MARK: - Published Properties

    /// User authentication state
    @Published private(set) var isAuthenticated = false

    /// Loading state for async operations
    @Published private(set) var isLoading = false

    /// Currently authenticated user
    @Published private(set) var currentUser: User?

    /// General error message to display to user
    @Published var errorMessage: String?

    /// Field-specific validation errors
    @Published var validationErrors: [String: String] = [:]

    /// Password strength for registration
    @Published private(set) var passwordStrength: PasswordStrength?

    /// Success message for operations like password reset
    @Published var successMessage: String?

    // MARK: - Dependencies

    private let authService: AuthService
    private let keychain: KeychainManager

    // MARK: - Private State

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    /// Initialize AuthViewModel with dependency injection
    /// - Parameters:
    ///   - authService: Authentication service (defaults to shared instance)
    ///   - keychain: Keychain manager (defaults to shared instance)
    init(
        authService: AuthService = .shared,
        keychain: KeychainManager = .shared
    ) {
        self.authService = authService
        self.keychain = keychain

        // Check authentication status on initialization
        Task {
            await checkAuthStatus()
        }
    }

    // MARK: - Authentication Status

    /// Check if user is already authenticated (e.g., on app launch)
    /// - Note: Automatically fetches user profile if tokens exist
    func checkAuthStatus() async {
        print("🔐 AuthViewModel: Checking authentication status...")

        guard authService.isAuthenticated() else {
            print("🔓 AuthViewModel: User not authenticated")
            isAuthenticated = false
            currentUser = nil
            return
        }

        print("🔑 AuthViewModel: Tokens found, fetching user profile...")

        do {
            isLoading = true
            currentUser = try await authService.fetchUserProfile()
            isAuthenticated = true
            print("✅ AuthViewModel: User authenticated - \(currentUser?.email ?? "unknown")")
        } catch {
            print("❌ AuthViewModel: Failed to fetch user profile: \(error)")
            // Token might be expired, clear auth state
            await logout()
        }

        isLoading = false
    }

    // MARK: - Login

    /// Login user with email and password
    /// - Parameters:
    ///   - email: User email address
    ///   - password: User password
    /// - Returns: Success status
    @discardableResult
    func login(email: String, password: String) async -> Bool {
        print("🔐 AuthViewModel: Starting login for \(email)")

        // Clear previous errors
        clearError()
        resetValidation()

        // Validate inputs
        guard validateLoginForm(email: email, password: password) else {
            print("❌ AuthViewModel: Login validation failed")
            return false
        }

        isLoading = true

        do {
            currentUser = try await authService.login(email: email, password: password)
            isAuthenticated = true
            isLoading = false

            print("✅ AuthViewModel: Login successful for \(email)")
            return true

        } catch let error as AuthError {
            handleAuthError(error)
            isLoading = false
            print("❌ AuthViewModel: Login failed - \(error.localizedDescription)")
            return false

        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
            isLoading = false
            print("❌ AuthViewModel: Login failed with unexpected error - \(error)")
            return false
        }
    }

    // MARK: - Registration

    /// Register new user account
    /// - Parameters:
    ///   - firstName: User's first name
    ///   - lastName: User's last name
    ///   - email: User's email address
    ///   - password: User's password
    ///   - nativeLanguage: User's native language code (e.g., "en")
    ///   - targetLanguage: User's target learning language code (e.g., "es")
    /// - Returns: Registration response indicating if email verification is needed
    @discardableResult
    func register(
        firstName: String,
        lastName: String,
        email: String,
        password: String,
        nativeLanguage: String,
        targetLanguage: String
    ) async -> RegisterResponse? {
        print("🔐 AuthViewModel: Starting registration for \(email)")

        // Clear previous errors
        clearError()
        resetValidation()

        // Validate registration form
        guard validateRegistrationForm(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password,
            nativeLanguage: nativeLanguage,
            targetLanguage: targetLanguage
        ) else {
            print("❌ AuthViewModel: Registration validation failed")
            return nil
        }

        isLoading = true

        do {
            let response = try await authService.register(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName,
                nativeLanguage: nativeLanguage,
                targetLanguage: targetLanguage
            )

            // If auto-login was successful, fetch user profile
            if response.tokens != nil {
                currentUser = try await authService.fetchUserProfile()
                isAuthenticated = true
            }

            isLoading = false
            print("✅ AuthViewModel: Registration successful - \(response.message)")
            return response

        } catch let error as AuthError {
            handleAuthError(error)
            isLoading = false
            print("❌ AuthViewModel: Registration failed - \(error.localizedDescription)")
            return nil

        } catch {
            errorMessage = "Registration failed. Please try again."
            isLoading = false
            print("❌ AuthViewModel: Registration failed with unexpected error - \(error)")
            return nil
        }
    }

    // MARK: - Email Verification

    /// Verify user email with verification code
    /// - Parameters:
    ///   - email: User's email address
    ///   - code: Verification code received via email
    /// - Returns: Success status
    @discardableResult
    func verifyEmail(email: String, code: String) async -> Bool {
        print("🔐 AuthViewModel: Verifying email for \(email)")

        clearError()

        // Validate inputs
        if let emailError = validateEmail(email) {
            validationErrors["email"] = emailError
            return false
        }

        guard !code.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationErrors["code"] = "Verification code is required"
            return false
        }

        isLoading = true

        do {
            currentUser = try await authService.verifyEmail(email: email, code: code)
            isAuthenticated = true
            isLoading = false

            successMessage = "Email verified successfully!"
            print("✅ AuthViewModel: Email verification successful")
            return true

        } catch let error as AuthError {
            handleAuthError(error)
            isLoading = false
            print("❌ AuthViewModel: Email verification failed - \(error.localizedDescription)")
            return false

        } catch {
            errorMessage = "Verification failed. Please try again."
            isLoading = false
            print("❌ AuthViewModel: Email verification failed with unexpected error - \(error)")
            return false
        }
    }

    /// Resend verification code to user's email
    /// - Parameter email: User's email address
    /// - Returns: Success status
    @discardableResult
    func resendVerificationCode(email: String) async -> Bool {
        print("🔐 AuthViewModel: Resending verification code to \(email)")

        clearError()

        // Validate email
        if let emailError = validateEmail(email) {
            validationErrors["email"] = emailError
            return false
        }

        isLoading = true

        do {
            try await authService.resendVerificationCode(email: email)
            isLoading = false

            successMessage = "Verification code sent! Check your email."
            print("✅ AuthViewModel: Verification code resent successfully")
            return true

        } catch let error as AuthError {
            handleAuthError(error)
            isLoading = false
            print("❌ AuthViewModel: Resend verification failed - \(error.localizedDescription)")
            return false

        } catch {
            errorMessage = "Failed to resend code. Please try again."
            isLoading = false
            print("❌ AuthViewModel: Resend verification failed with unexpected error - \(error)")
            return false
        }
    }

    // MARK: - Password Reset

    /// Request password reset (sends code to email)
    /// - Parameter email: User's email address
    /// - Returns: Success status
    @discardableResult
    func forgotPassword(email: String) async -> Bool {
        print("🔐 AuthViewModel: Requesting password reset for \(email)")

        clearError()

        // Validate email
        if let emailError = validateEmail(email) {
            validationErrors["email"] = emailError
            return false
        }

        isLoading = true

        do {
            try await authService.forgotPassword(email: email)
            isLoading = false

            successMessage = "Password reset code sent to your email!"
            print("✅ AuthViewModel: Password reset code sent successfully")
            return true

        } catch let error as AuthError {
            handleAuthError(error)
            isLoading = false
            print("❌ AuthViewModel: Forgot password failed - \(error.localizedDescription)")
            return false

        } catch {
            errorMessage = "Failed to send reset code. Please try again."
            isLoading = false
            print("❌ AuthViewModel: Forgot password failed with unexpected error - \(error)")
            return false
        }
    }

    /// Reset password with verification code
    /// - Parameters:
    ///   - email: User's email address
    ///   - code: Reset code received via email
    ///   - newPassword: New password to set
    /// - Returns: Success status
    @discardableResult
    func resetPassword(email: String, code: String, newPassword: String) async -> Bool {
        print("🔐 AuthViewModel: Resetting password for \(email)")

        clearError()
        resetValidation()

        // Validate inputs
        if let emailError = validateEmail(email) {
            validationErrors["email"] = emailError
        }

        if code.trimmingCharacters(in: .whitespaces).isEmpty {
            validationErrors["code"] = "Reset code is required"
        }

        if let passwordError = validatePassword(newPassword) {
            validationErrors["password"] = passwordError
        }

        guard validationErrors.isEmpty else {
            return false
        }

        isLoading = true

        do {
            try await authService.resetPassword(email: email, code: code, newPassword: newPassword)
            isLoading = false

            successMessage = "Password reset successfully! Please login."
            print("✅ AuthViewModel: Password reset successful")
            return true

        } catch let error as AuthError {
            handleAuthError(error)
            isLoading = false
            print("❌ AuthViewModel: Password reset failed - \(error.localizedDescription)")
            return false

        } catch {
            errorMessage = "Password reset failed. Please try again."
            isLoading = false
            print("❌ AuthViewModel: Password reset failed with unexpected error - \(error)")
            return false
        }
    }

    // MARK: - Logout

    /// Logout current user and clear all authentication data
    func logout() async {
        print("🔐 AuthViewModel: Logging out user")

        isLoading = true

        do {
            try await authService.logout()
        } catch {
            // Ignore logout errors, still clear local state
            print("⚠️ AuthViewModel: Logout API call failed (continuing with local logout)")
        }

        // Clear local state
        isAuthenticated = false
        currentUser = nil
        clearError()
        resetValidation()
        passwordStrength = nil
        successMessage = nil

        isLoading = false
        print("✅ AuthViewModel: Logout completed")
    }

    // MARK: - Validation Methods

    /// Validate email format
    /// - Parameter email: Email address to validate
    /// - Returns: Error message if invalid, nil if valid
    func validateEmail(_ email: String) -> String? {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)

        if trimmedEmail.isEmpty {
            return "Email is required"
        }

        if !AuthService.isValidEmail(trimmedEmail) {
            return "Please enter a valid email address"
        }

        return nil
    }

    /// Validate password strength
    /// - Parameter password: Password to validate
    /// - Returns: Error message if invalid, nil if valid
    func validatePassword(_ password: String) -> String? {
        if password.isEmpty {
            return "Password is required"
        }

        let validation = AuthService.isValidPassword(password)
        if !validation.valid {
            return validation.message
        }

        return nil
    }

    /// Validate name (first or last name)
    /// - Parameter name: Name to validate
    /// - Returns: Error message if invalid, nil if valid
    func validateName(_ name: String) -> String? {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        if trimmedName.isEmpty {
            return "Name is required"
        }

        if !AuthService.isValidName(trimmedName) {
            return "Name must be between 2 and 50 characters"
        }

        return nil
    }

    /// Validate login form
    /// - Parameters:
    ///   - email: Email address
    ///   - password: Password
    /// - Returns: True if form is valid
    private func validateLoginForm(email: String, password: String) -> Bool {
        var isValid = true

        if let emailError = validateEmail(email) {
            validationErrors["email"] = emailError
            isValid = false
        }

        if password.isEmpty {
            validationErrors["password"] = "Password is required"
            isValid = false
        }

        return isValid
    }

    /// Validate registration form
    /// - Parameters:
    ///   - firstName: First name
    ///   - lastName: Last name
    ///   - email: Email address
    ///   - password: Password
    ///   - nativeLanguage: Native language code
    ///   - targetLanguage: Target language code
    /// - Returns: True if form is valid
    private func validateRegistrationForm(
        firstName: String,
        lastName: String,
        email: String,
        password: String,
        nativeLanguage: String,
        targetLanguage: String
    ) -> Bool {
        var isValid = true

        if let firstNameError = validateName(firstName) {
            validationErrors["firstName"] = firstNameError
            isValid = false
        }

        if let lastNameError = validateName(lastName) {
            validationErrors["lastName"] = lastNameError
            isValid = false
        }

        if let emailError = validateEmail(email) {
            validationErrors["email"] = emailError
            isValid = false
        }

        if let passwordError = validatePassword(password) {
            validationErrors["password"] = passwordError
            isValid = false
        }

        if nativeLanguage.trimmingCharacters(in: .whitespaces).isEmpty {
            validationErrors["nativeLanguage"] = "Please select your native language"
            isValid = false
        }

        if targetLanguage.trimmingCharacters(in: .whitespaces).isEmpty {
            validationErrors["targetLanguage"] = "Please select a language to learn"
            isValid = false
        }

        if nativeLanguage == targetLanguage && !nativeLanguage.isEmpty {
            validationErrors["targetLanguage"] = "Target language must be different from native language"
            isValid = false
        }

        return isValid
    }

    // MARK: - Password Strength

    /// Check password strength for visual feedback
    /// - Parameter password: Password to check
    /// - Returns: Password strength level
    func checkPasswordStrength(_ password: String) -> PasswordStrength {
        if password.isEmpty {
            return .weak
        }

        var score = 0

        // Length check
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.count >= 16 { score += 1 }

        // Character variety checks
        if password.range(of: "[a-z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[^a-zA-Z0-9]", options: .regularExpression) != nil { score += 1 }

        let strength: PasswordStrength
        switch score {
        case 0...2:
            strength = .weak
        case 3...4:
            strength = .medium
        case 5...6:
            strength = .strong
        default:
            strength = .veryStrong
        }

        return strength
    }

    // MARK: - Error Handling

    /// Handle AuthError and set appropriate error messages
    /// - Parameter error: AuthError to handle
    private func handleAuthError(_ error: AuthError) {
        errorMessage = error.localizedDescription

        // Set specific field errors for certain error types
        switch error {
        case .invalidCredentials:
            validationErrors["email"] = " "
            validationErrors["password"] = " "
        case .emailNotVerified:
            break
        case .emailAlreadyExists:
            validationErrors["email"] = error.localizedDescription
        case .weakPassword:
            validationErrors["password"] = error.localizedDescription
        case .invalidVerificationCode:
            validationErrors["code"] = error.localizedDescription
        default:
            break
        }
    }

    /// Clear general error message
    func clearError() {
        errorMessage = nil
        successMessage = nil
    }

    /// Reset all field validation errors
    func resetValidation() {
        validationErrors.removeAll()
    }

    /// Clear specific field validation error
    /// - Parameter field: Field name to clear error for
    func clearFieldError(_ field: String) {
        validationErrors.removeValue(forKey: field)
    }

    // MARK: - User Profile

    /// Refresh current user profile from server
    /// - Returns: Success status
    @discardableResult
    func refreshUserProfile() async -> Bool {
        guard isAuthenticated else {
            print("⚠️ AuthViewModel: Cannot refresh profile - user not authenticated")
            return false
        }

        print("🔄 AuthViewModel: Refreshing user profile...")

        do {
            currentUser = try await authService.fetchUserProfile()
            print("✅ AuthViewModel: User profile refreshed successfully")
            return true

        } catch {
            print("❌ AuthViewModel: Failed to refresh user profile - \(error)")

            // If token is expired, logout
            if let authError = error as? AuthError {
                switch authError {
                case .tokenExpired, .notAuthenticated:
                    await logout()
                default:
                    break
                }
            }

            return false
        }
    }

    /// Update user profile
    /// - Parameters:
    ///   - firstName: First name
    ///   - lastName: Last name
    ///   - username: Username
    ///   - nativeLanguage: Native language code
    /// - Returns: Success status
    @discardableResult
    func updateProfile(
        firstName: String?,
        lastName: String?,
        username: String?,
        nativeLanguage: String?
    ) async -> Bool {
        guard isAuthenticated else {
            print("⚠️ AuthViewModel: Cannot update profile - user not authenticated")
            errorMessage = "You must be logged in to update your profile"
            return false
        }

        print("🔐 AuthViewModel: Updating user profile...")

        // Clear previous errors
        clearError()
        resetValidation()

        isLoading = true

        do {
            let updatedUser = try await authService.updateProfile(
                firstName: firstName,
                lastName: lastName,
                username: username,
                nativeLanguage: nativeLanguage
            )

            // Update local state with new user data
            currentUser = updatedUser
            isLoading = false

            print("✅ AuthViewModel: Profile updated successfully")
            return true

        } catch let error as AuthError {
            handleAuthError(error)
            isLoading = false
            print("❌ AuthViewModel: Profile update failed - \(error.localizedDescription)")
            return false

        } catch {
            errorMessage = "Failed to update profile. Please try again."
            isLoading = false
            print("❌ AuthViewModel: Profile update failed with unexpected error - \(error)")
            return false
        }
    }

    /// Change user password
    /// - Parameters:
    ///   - currentPassword: Current password
    ///   - newPassword: New password
    /// - Returns: Success status
    @discardableResult
    func changePassword(currentPassword: String, newPassword: String) async -> Bool {
        guard isAuthenticated else {
            print("⚠️ AuthViewModel: Cannot change password - user not authenticated")
            errorMessage = "You must be logged in to change your password"
            return false
        }

        print("🔐 AuthViewModel: Changing password...")

        // Clear previous errors
        clearError()
        resetValidation()

        // Validate passwords
        if currentPassword.isEmpty {
            validationErrors["currentPassword"] = "Current password is required"
            return false
        }

        if let passwordError = validatePassword(newPassword) {
            validationErrors["newPassword"] = passwordError
            return false
        }

        isLoading = true

        do {
            try await authService.changePassword(currentPassword: currentPassword, newPassword: newPassword)
            isLoading = false

            print("✅ AuthViewModel: Password changed successfully")
            return true

        } catch let error as AuthError {
            handleAuthError(error)
            isLoading = false
            print("❌ AuthViewModel: Password change failed - \(error.localizedDescription)")
            return false

        } catch {
            errorMessage = "Failed to change password. Please try again."
            isLoading = false
            print("❌ AuthViewModel: Password change failed with unexpected error - \(error)")
            return false
        }
    }
}

// MARK: - Convenience Properties

extension AuthViewModel {
    /// Check if user's email is verified
    var isEmailVerified: Bool {
        return currentUser?.emailVerified ?? false
    }

    /// Check if user has premium subscription
    var isPremiumUser: Bool {
        return currentUser?.isPremium ?? false
    }

    /// Get user's display name
    var userDisplayName: String {
        return currentUser?.displayName ?? "User"
    }

    /// Get user's email
    var userEmail: String {
        return currentUser?.email ?? ""
    }
}

// MARK: - Mock Support

#if DEBUG
extension AuthViewModel {
    /// Create mock view model for previews and testing
    /// - Parameter user: Mock user to use
    /// - Returns: Configured AuthViewModel
    static func mock(user: User? = .mock, isAuthenticated: Bool = true) -> AuthViewModel {
        let viewModel = AuthViewModel()
        viewModel.currentUser = user
        viewModel.isAuthenticated = isAuthenticated
        return viewModel
    }

    /// Create mock view model with error state
    /// - Parameter error: Error message to display
    /// - Returns: Configured AuthViewModel with error
    static func mockWithError(_ error: String) -> AuthViewModel {
        let viewModel = AuthViewModel()
        viewModel.errorMessage = error
        return viewModel
    }

    /// Create mock view model with loading state
    /// - Returns: Configured AuthViewModel in loading state
    static func mockLoading() -> AuthViewModel {
        let viewModel = AuthViewModel()
        viewModel.isLoading = true
        return viewModel
    }
}
#endif
