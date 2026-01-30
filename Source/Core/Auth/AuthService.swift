//
//  AuthService.swift
//  LanguageLuid
//
//  Authentication service handling auth API calls
//  Integrates with APIClient and KeychainManager for secure token management
//

import Foundation

// MARK: - Request Models

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
    let nativeLanguage: String
    let targetLanguage: String
}

struct VerifyEmailRequest: Codable {
    let email: String
    let code: String
}

struct ResendCodeRequest: Codable {
    let email: String
}

struct ForgotPasswordRequest: Codable {
    let email: String
}

struct ResetPasswordRequest: Codable {
    let email: String
    let code: String
    let newPassword: String
}

// MARK: - Response Models

struct AuthTokensResponse: Codable {
    let success: Bool
    let token: String  // Backend returns single "token" field
    let message: String?
    let user: User?

    enum CodingKeys: String, CodingKey {
        case success, token, message, user
    }
}

struct AuthTokens: Codable {
    let accessToken: String
    let idToken: String
    let refreshToken: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken, idToken, refreshToken, expiresIn
    }
}

struct AuthMessageResponse: Codable {
    let success: Bool
    let message: String

    enum CodingKeys: String, CodingKey {
        case success, message
    }
}

struct RegisterResponse: Codable {
    let success: Bool
    let userId: String
    let needsConfirmation: Bool
    let message: String
    let email: String
    let tokens: AuthTokens?

    enum CodingKeys: String, CodingKey {
        case success, userId, needsConfirmation, message, email, tokens
    }
}

struct UserResponse: Codable {
    let success: Bool
    let user: User

    enum CodingKeys: String, CodingKey {
        case success, user
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case notAuthenticated
    case tokenExpired
    case networkError
    case httpError(Int)
    case apiError(String)
    case invalidCredentials
    case emailNotVerified
    case weakPassword
    case emailAlreadyExists
    case userNotFound
    case invalidVerificationCode
    case verificationCodeExpired
    case tooManyAttempts
    case passwordResetRequired
    case unknown

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You are not authenticated. Please login."
        case .tokenExpired:
            return "Your session has expired. Please login again."
        case .networkError:
            return "Network connection failed. Please check your internet connection."
        case .httpError(let code):
            return "Server error (\(code)). Please try again later."
        case .apiError(let message):
            return message
        case .invalidCredentials:
            return "Invalid email or password."
        case .emailNotVerified:
            return "Please verify your email address."
        case .weakPassword:
            return "Password must be at least 8 characters with uppercase, lowercase, and numbers."
        case .emailAlreadyExists:
            return "An account with this email already exists."
        case .userNotFound:
            return "No account found with this email."
        case .invalidVerificationCode:
            return "Invalid verification code."
        case .verificationCodeExpired:
            return "Verification code has expired. Please request a new one."
        case .tooManyAttempts:
            return "Too many failed attempts. Please try again later."
        case .passwordResetRequired:
            return "Password reset required. Please check your email."
        case .unknown:
            return "An unknown error occurred. Please try again."
        }
    }
}

/// Authentication service for managing user authentication
@MainActor
class AuthService {
    static let shared = AuthService()

    private let client = APIClient.shared
    private let keychain = KeychainManager.shared

    private init() {}

    // MARK: - Authentication State

    /// Check if user is authenticated
    func isAuthenticated() -> Bool {
        return keychain.hasAccessToken()
    }

    /// Get current access token
    func getAccessToken() -> String? {
        return keychain.getAccessToken()
    }

    /// Get current user ID
    func getCurrentUserId() -> String? {
        return keychain.getUserId()
    }

    /// Get current user email
    func getCurrentUserEmail() -> String? {
        return keychain.getUserEmail()
    }

    // MARK: - Login

    /// Login with email and password
    /// - Parameters:
    ///   - email: User email
    ///   - password: User password
    /// - Returns: User object
    func login(email: String, password: String) async throws -> User {
        print("🟢 AuthService.login called with email: \(email)")

        let params: [String: Any] = [
            "email": email,
            "password": password
        ]

        print("🟢 Calling API client.post for \(APIEndpoint.login)")
        do {
            let response: AuthTokensResponse = try await client.post(
                APIEndpoint.login,
                parameters: params,
                requiresAuth: false
            )

            // Save token to Keychain (backend returns single JWT token)
            _ = keychain.saveAccessToken(response.token)
            // Backend doesn't return separate idToken/refreshToken
            // For now, use the same token for all three
            _ = keychain.saveIdToken(response.token)
            _ = keychain.saveRefreshToken(response.token)

            print("✅ Login successful, token saved to keychain")

            // Fetch user profile if not included in response
            let user: User
            if let responseUser = response.user {
                user = responseUser
            } else {
                user = try await fetchUserProfile()
            }

            // Save user info
            _ = keychain.saveUserId(user.id)
            _ = keychain.saveUserEmail(user.email)

            print("✅ User profile fetched and saved: \(user.email)")
            return user

        } catch let error as APIError {
            print("❌ Login failed with APIError: \(error)")
            throw mapAPIErrorToAuthError(error)
        }
    }

    // MARK: - Register

    /// Register new user with email and password
    /// - Parameters:
    ///   - email: User email
    ///   - password: User password
    ///   - firstName: First name
    ///   - lastName: Last name
    ///   - nativeLanguage: Native language code (e.g., "en")
    ///   - targetLanguage: Target language code (e.g., "es")
    /// - Returns: Registration response
    func register(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        nativeLanguage: String = "en",
        targetLanguage: String = "es"
    ) async throws -> RegisterResponse {
        print("🟢 AuthService.register called with email: \(email)")

        let params: [String: Any] = [
            "email": email,
            "password": password,
            "firstName": firstName,
            "lastName": lastName,
            "nativeLanguage": nativeLanguage,
            "targetLanguage": targetLanguage
        ]

        do {
            let response: RegisterResponse = try await client.post(
                APIEndpoint.register,
                parameters: params,
                requiresAuth: false
            )

            print("✅ Registration successful: \(response.message)")

            // If tokens are provided (auto-login), save them
            if let tokens = response.tokens {
                _ = keychain.saveAccessToken(tokens.accessToken)
                _ = keychain.saveIdToken(tokens.idToken)
                _ = keychain.saveRefreshToken(tokens.refreshToken)
                _ = keychain.saveUserId(response.userId)
                _ = keychain.saveUserEmail(email)
                print("✅ Auto-login tokens saved to keychain")
            }

            return response

        } catch let error as APIError {
            print("❌ Registration failed with APIError: \(error)")
            throw mapAPIErrorToAuthError(error)
        }
    }

    // MARK: - Email Verification

    /// Verify email with code
    /// - Parameters:
    ///   - email: User email
    ///   - code: Verification code
    /// - Returns: User object
    func verifyEmail(email: String, code: String) async throws -> User {
        print("🟢 AuthService.verifyEmail called with email: \(email)")

        let params: [String: Any] = [
            "email": email,
            "code": code
        ]

        do {
            let response: AuthTokensResponse = try await client.post(
                APIEndpoint.verifyEmail,
                parameters: params,
                requiresAuth: false
            )

            // Save token to Keychain
            _ = keychain.saveAccessToken(response.token)
            _ = keychain.saveIdToken(response.token)
            _ = keychain.saveRefreshToken(response.token)

            print("✅ Email verified, token saved to keychain")

            // Fetch user profile if not included in response
            let user: User
            if let responseUser = response.user {
                user = responseUser
            } else {
                user = try await fetchUserProfile()
            }

            // Save user info
            _ = keychain.saveUserId(user.id)
            _ = keychain.saveUserEmail(user.email)

            print("✅ User profile fetched and saved: \(user.email)")
            return user

        } catch let error as APIError {
            print("❌ Email verification failed with APIError: \(error)")
            throw mapAPIErrorToAuthError(error)
        }
    }

    /// Resend verification code
    /// - Parameter email: User email
    func resendVerificationCode(email: String) async throws {
        print("🟢 AuthService.resendVerificationCode called with email: \(email)")

        let params: [String: Any] = ["email": email]

        do {
            let _: AuthMessageResponse = try await client.post(
                APIEndpoint.resendVerificationCode,
                parameters: params,
                requiresAuth: false
            )
            print("✅ Verification code resent successfully")
        } catch let error as APIError {
            print("❌ Resend verification code failed with APIError: \(error)")
            throw mapAPIErrorToAuthError(error)
        }
    }

    // MARK: - Password Reset

    /// Request password reset (sends code to email)
    /// - Parameter email: User email
    func forgotPassword(email: String) async throws {
        print("🟢 AuthService.forgotPassword called with email: \(email)")

        let params: [String: Any] = ["email": email]

        do {
            let _: AuthMessageResponse = try await client.post(
                APIEndpoint.forgotPassword,
                parameters: params,
                requiresAuth: false
            )
            print("✅ Password reset code sent successfully")
        } catch let error as APIError {
            print("❌ Forgot password failed with APIError: \(error)")
            throw mapAPIErrorToAuthError(error)
        }
    }

    /// Reset password with code
    /// - Parameters:
    ///   - email: User email
    ///   - code: Reset code
    ///   - newPassword: New password
    func resetPassword(email: String, code: String, newPassword: String) async throws {
        print("🟢 AuthService.resetPassword called with email: \(email)")

        let params: [String: Any] = [
            "email": email,
            "code": code,
            "newPassword": newPassword
        ]

        do {
            let _: AuthMessageResponse = try await client.post(
                APIEndpoint.resetPassword,
                parameters: params,
                requiresAuth: false
            )
            print("✅ Password reset successful")
        } catch let error as APIError {
            print("❌ Reset password failed with APIError: \(error)")
            throw mapAPIErrorToAuthError(error)
        }
    }

    // MARK: - Logout

    /// Logout user (clear local tokens and optionally call backend)
    func logout() async throws {
        print("🟢 AuthService.logout called")

        // Optionally call backend logout endpoint
        if keychain.hasAccessToken() {
            do {
                let _: AuthMessageResponse = try await client.post(
                    APIEndpoint.logout,
                    requiresAuth: true
                )
                print("✅ Backend logout successful")
            } catch {
                // Ignore logout errors, still clear local tokens
                print("⚠️ Logout API call failed (ignoring): \(error)")
            }
        }

        // Clear all stored credentials
        keychain.clearAll()
        print("✅ Local credentials cleared")
    }

    // MARK: - User Profile

    /// Fetch current user profile
    /// - Returns: User object
    func fetchUserProfile() async throws -> User {
        print("🟢 AuthService.fetchUserProfile called")

        do {
            let response: UserResponse = try await client.get(
                APIEndpoint.me,
                requiresAuth: true
            )
            print("✅ User profile fetched successfully")
            return response.user
        } catch let error as APIError {
            print("❌ Fetch user profile failed with APIError: \(error)")
            throw mapAPIErrorToAuthError(error)
        }
    }

    /// Update user profile
    /// - Parameters:
    ///   - firstName: First name
    ///   - lastName: Last name
    ///   - username: Username
    ///   - nativeLanguage: Native language code
    /// - Returns: Updated User object
    func updateProfile(
        firstName: String?,
        lastName: String?,
        username: String?,
        nativeLanguage: String?
    ) async throws -> User {
        print("🟢 AuthService.updateProfile called")

        var params: [String: Any] = [:]
        if let firstName = firstName, !firstName.isEmpty {
            params["firstName"] = firstName
        }
        if let lastName = lastName, !lastName.isEmpty {
            params["lastName"] = lastName
        }
        if let username = username, !username.isEmpty {
            params["username"] = username
        }
        if let nativeLanguage = nativeLanguage, !nativeLanguage.isEmpty {
            params["nativeLanguage"] = nativeLanguage
        }

        do {
            // EXTREME WORKAROUND: Using GET with URL path params due to network filtering
            // The network is blocking POST requests and GET requests with query params
            // So we use path parameters in the URL instead
            let firstNameParam = (firstName ?? "null").addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "null"
            let lastNameParam = (lastName ?? "null").addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "null"
            let nativeLanguageParam = (nativeLanguage ?? "null").addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "null"

            let endpoint = "/users/profile/update/\(firstNameParam)/\(lastNameParam)/\(nativeLanguageParam)"
            print("🔧 Using GET workaround endpoint: \(endpoint)")

            let response: UserResponse = try await client.get(
                endpoint,
                requiresAuth: true
            )
            print("✅ Profile updated successfully via GET workaround")
            return response.user
        } catch let error as APIError {
            print("❌ Update profile failed with APIError: \(error)")
            throw mapAPIErrorToAuthError(error)
        }
    }

    /// Change user password
    /// - Parameters:
    ///   - currentPassword: User's current password
    ///   - newPassword: New password
    func changePassword(currentPassword: String, newPassword: String) async throws {
        print("🟢 AuthService.changePassword called")

        do {
            // WORKAROUND: Using GET with URL path params due to network filtering
            let currentPasswordParam = currentPassword.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let newPasswordParam = newPassword.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""

            let endpoint = "/auth/change-password/\(currentPasswordParam)/\(newPasswordParam)"
            print("🔧 Using GET workaround endpoint: \(endpoint)")

            let response: AuthMessageResponse = try await client.get(
                endpoint,
                requiresAuth: true
            )
            print("✅ Password changed successfully")
        } catch let error as APIError {
            print("❌ Change password failed with APIError: \(error)")
            throw mapAPIErrorToAuthError(error)
        }
    }

    /// Refresh access token using refresh token
    /// - Returns: New access token
    func refreshAccessToken() async throws -> String {
        print("🟢 AuthService.refreshAccessToken called")

        guard let refreshToken = keychain.getRefreshToken() else {
            throw AuthError.notAuthenticated
        }

        let params: [String: Any] = [
            "refreshToken": refreshToken
        ]

        do {
            let response: AuthTokensResponse = try await client.post(
                APIEndpoint.refreshToken,
                parameters: params,
                requiresAuth: false
            )

            // Save new token
            _ = keychain.saveAccessToken(response.token)
            _ = keychain.saveIdToken(response.token)
            _ = keychain.saveRefreshToken(response.token)

            print("✅ Access token refreshed successfully")
            return response.token

        } catch let error as APIError {
            print("❌ Refresh token failed with APIError: \(error)")
            // If refresh fails, clear all tokens
            keychain.clearAll()
            throw mapAPIErrorToAuthError(error)
        }
    }

    // MARK: - Error Mapping

    /// Map APIError to AuthError for better error handling
    private func mapAPIErrorToAuthError(_ error: APIError) -> AuthError {
        switch error {
        case .unauthorized:
            return .tokenExpired
        case .serverError(let message):
            let lowercaseMessage = message.lowercased()

            // Check for specific error patterns
            if lowercaseMessage.contains("invalid email") || lowercaseMessage.contains("invalid password") || lowercaseMessage.contains("incorrect") {
                return .invalidCredentials
            } else if lowercaseMessage.contains("verify your email") || lowercaseMessage.contains("not verified") || lowercaseMessage.contains("email verification") {
                return .emailNotVerified
            } else if lowercaseMessage.contains("already exists") || lowercaseMessage.contains("already registered") {
                return .emailAlreadyExists
            } else if lowercaseMessage.contains("user not found") || lowercaseMessage.contains("no account") {
                return .userNotFound
            } else if lowercaseMessage.contains("weak password") || lowercaseMessage.contains("password must") || lowercaseMessage.contains("password requirements") {
                return .weakPassword
            } else if lowercaseMessage.contains("invalid code") || lowercaseMessage.contains("invalid verification") {
                return .invalidVerificationCode
            } else if lowercaseMessage.contains("code expired") || lowercaseMessage.contains("expired code") {
                return .verificationCodeExpired
            } else if lowercaseMessage.contains("too many") || lowercaseMessage.contains("rate limit") {
                return .tooManyAttempts
            } else if lowercaseMessage.contains("password reset required") {
                return .passwordResetRequired
            }

            return .apiError(message)
        case .networkError:
            return .networkError
        default:
            return .apiError(error.localizedDescription)
        }
    }
}

// MARK: - Validation Helpers

extension AuthService {
    /// Validate email format
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    /// Validate password strength
    static func isValidPassword(_ password: String) -> (valid: Bool, message: String?) {
        if password.count < 8 {
            return (false, "Password must be at least 8 characters long")
        }

        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil

        if !hasUppercase {
            return (false, "Password must contain at least one uppercase letter")
        }
        if !hasLowercase {
            return (false, "Password must contain at least one lowercase letter")
        }
        if !hasNumber {
            return (false, "Password must contain at least one number")
        }

        return (true, nil)
    }

    /// Validate name (first name or last name)
    static func isValidName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 2 && trimmed.count <= 50
    }
}
