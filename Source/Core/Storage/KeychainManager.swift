//
//  KeychainManager.swift
//  LanguageLuid
//
//  Secure storage for authentication tokens and sensitive data
//  Uses iOS Keychain with UserDefaults fallback for simulator compatibility
//

import Foundation
import Security

/// Manages secure storage of sensitive data in iOS Keychain
class KeychainManager {
    static let shared = KeychainManager()

    private init() {}

    // MARK: - Keychain Keys

    private enum Keys {
        static let accessToken = "com.luid.languageluid.accessToken"
        static let idToken = "com.luid.languageluid.idToken"
        static let refreshToken = "com.luid.languageluid.refreshToken"
        static let userId = "com.luid.languageluid.userId"
        static let userEmail = "com.luid.languageluid.userEmail"
    }

    // MARK: - Access Token

    /// Save access token to Keychain
    func saveAccessToken(_ token: String) -> Bool {
        return save(token, forKey: Keys.accessToken)
    }

    /// Get access token from Keychain
    func getAccessToken() -> String? {
        return get(forKey: Keys.accessToken)
    }

    /// Delete access token from Keychain
    func deleteAccessToken() -> Bool {
        return delete(forKey: Keys.accessToken)
    }

    // MARK: - ID Token

    /// Save ID token to Keychain
    func saveIdToken(_ token: String) -> Bool {
        return save(token, forKey: Keys.idToken)
    }

    /// Get ID token from Keychain
    func getIdToken() -> String? {
        return get(forKey: Keys.idToken)
    }

    /// Delete ID token from Keychain
    func deleteIdToken() -> Bool {
        return delete(forKey: Keys.idToken)
    }

    // MARK: - Refresh Token

    /// Save refresh token to Keychain
    func saveRefreshToken(_ token: String) -> Bool {
        return save(token, forKey: Keys.refreshToken)
    }

    /// Get refresh token from Keychain
    func getRefreshToken() -> String? {
        return get(forKey: Keys.refreshToken)
    }

    /// Delete refresh token from Keychain
    func deleteRefreshToken() -> Bool {
        return delete(forKey: Keys.refreshToken)
    }

    // MARK: - User ID

    /// Save user ID to Keychain
    func saveUserId(_ userId: String) -> Bool {
        return save(userId, forKey: Keys.userId)
    }

    /// Get user ID from Keychain
    func getUserId() -> String? {
        return get(forKey: Keys.userId)
    }

    /// Delete user ID from Keychain
    func deleteUserId() -> Bool {
        return delete(forKey: Keys.userId)
    }

    // MARK: - User Email

    /// Save user email to Keychain
    func saveUserEmail(_ email: String) -> Bool {
        return save(email, forKey: Keys.userEmail)
    }

    /// Get user email from Keychain
    func getUserEmail() -> String? {
        return get(forKey: Keys.userEmail)
    }

    /// Delete user email from Keychain
    func deleteUserEmail() -> Bool {
        return delete(forKey: Keys.userEmail)
    }

    // MARK: - Clear All

    /// Clear all stored credentials
    func clearAll() {
        _ = deleteAccessToken()
        _ = deleteIdToken()
        _ = deleteRefreshToken()
        _ = deleteUserId()
        _ = deleteUserEmail()

        print("🗑️ KeychainManager: All credentials cleared")
    }

    // MARK: - Authentication State

    /// Check if user has valid access token
    func hasAccessToken() -> Bool {
        return getAccessToken() != nil
    }

    /// Check if user has valid refresh token
    func hasRefreshToken() -> Bool {
        return getRefreshToken() != nil
    }

    /// Check if user is authenticated (has any token)
    func isAuthenticated() -> Bool {
        return hasAccessToken() || hasRefreshToken()
    }

    // MARK: - Generic Keychain Operations

    /// Save string value to Keychain (with UserDefaults fallback for simulator)
    private func save(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            print("⚠️ KeychainManager: Failed to encode value for key: \(key)")
            return false
        }

        // Delete existing item if present
        delete(forKey: key)

        // Add new item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        // If keychain fails with entitlement error (common in simulator), use UserDefaults fallback
        if status == errSecMissingEntitlement || status == -34018 {
            print("⚠️ Keychain unavailable (error \(status)), using UserDefaults fallback for: \(key)")
            UserDefaults.standard.set(value, forKey: key)
            return true
        }

        if status == errSecSuccess {
            print("✅ KeychainManager: Saved \(key)")
            return true
        } else {
            print("❌ KeychainManager: Failed to save \(key) with status: \(status)")
            return false
        }
    }

    /// Get string value from Keychain (with UserDefaults fallback for simulator)
    private func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let data = result as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        }

        // If keychain fails (common in simulator), try UserDefaults fallback
        if status == errSecMissingEntitlement || status == -34018 || status == errSecItemNotFound {
            if let value = UserDefaults.standard.string(forKey: key) {
                print("📦 Retrieved from UserDefaults fallback: \(key)")
                return value
            }
        }

        return nil
    }

    /// Delete item from Keychain (and UserDefaults fallback)
    private func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        // Also remove from UserDefaults fallback storage
        UserDefaults.standard.removeObject(forKey: key)

        return status == errSecSuccess || status == errSecItemNotFound
    }
}

// MARK: - Biometric Authentication Support

extension KeychainManager {
    /// Save token with biometric protection
    /// - Parameters:
    ///   - token: Token string to save
    ///   - key: Keychain key
    /// - Returns: Success status
    func saveBiometricToken(_ token: String, forKey key: String) -> Bool {
        guard let data = token.data(using: .utf8) else {
            return false
        }

        // Delete existing item
        delete(forKey: key)

        // Create access control for biometric authentication
        var error: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            .biometryCurrentSet,
            &error
        ) else {
            if let error = error?.takeRetainedValue() {
                print("❌ KeychainManager: Failed to create access control: \(error)")
            }
            return false
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessControl as String: access
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecSuccess {
            print("✅ KeychainManager: Saved biometric-protected token for key: \(key)")
            return true
        } else {
            print("❌ KeychainManager: Failed to save biometric token with status: \(status)")
            return false
        }
    }

    /// Get biometric-protected token
    /// - Parameter key: Keychain key
    /// - Returns: Token string if successful
    func getBiometricToken(forKey key: String) async -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseOperationPrompt as String: "Authenticate to access your account"
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let data = result as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        }

        print("❌ KeychainManager: Failed to retrieve biometric token with status: \(status)")
        return nil
    }
}

// MARK: - Debugging

extension KeychainManager {
    /// Print all stored keychain keys (values are masked)
    func debugPrintKeys() {
        print("🔑 KeychainManager Debug Info:")
        print("   Access Token: \(getAccessToken() != nil ? "✅ Present" : "❌ Missing")")
        print("   ID Token: \(getIdToken() != nil ? "✅ Present" : "❌ Missing")")
        print("   Refresh Token: \(getRefreshToken() != nil ? "✅ Present" : "❌ Missing")")
        print("   User ID: \(getUserId() != nil ? "✅ Present" : "❌ Missing")")
        print("   User Email: \(getUserEmail() ?? "❌ Missing")")
        print("   Is Authenticated: \(isAuthenticated() ? "✅ Yes" : "❌ No")")
    }

    /// Get all keychain values (for debugging only - use with caution!)
    func debugGetAllValues() -> [String: String?] {
        return [
            "accessToken": getAccessToken(),
            "idToken": getIdToken(),
            "refreshToken": getRefreshToken(),
            "userId": getUserId(),
            "userEmail": getUserEmail()
        ]
    }
}
