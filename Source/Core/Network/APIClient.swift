//
//  APIClient.swift
//  LanguageLuid
//
//  Core HTTP client using URLSession (NO external dependencies!)
//  Handles authentication, token injection, multipart uploads, and error handling
//

import Foundation
import os.log

/// API Error types
enum APIError: Error {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(String)
    case unauthorized
    case networkError(Error)
    case uploadFailed(String)
    case unknown

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let message):
            return message
        case .unauthorized:
            return "Your session has expired. Please login again."
        case .networkError(let error):
            // Provide specific error messages based on NSURLError codes
            let nsError = error as NSError
            switch nsError.code {
            case NSURLErrorTimedOut:
                return "Connection timed out. Please check your internet connection and try again."
            case NSURLErrorCannotConnectToHost:
                return "Cannot connect to server. Please check if the server is running and accessible."
            case NSURLErrorCannotFindHost:
                return "Cannot find server. Please check the server address and your DNS settings."
            case NSURLErrorNotConnectedToInternet:
                return "No internet connection. Please check your network settings."
            case NSURLErrorSecureConnectionFailed:
                return "Secure connection failed. There may be an SSL/TLS certificate issue."
            default:
                return "Network error: \(error.localizedDescription) (Code: \(nsError.code), Domain: \(nsError.domain))"
            }
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

/// HTTP Methods
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// API Client - Singleton for making HTTP requests
@MainActor
class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let uploadSession: URLSession
    private let baseURL: String
    private let keychainManager: KeychainManager
    private let logger = OSLog(subsystem: "com.luid.languageluid", category: "APIClient")

    private init() {
        // Standard session configuration
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = AppConfig.apiTimeout
        configuration.timeoutIntervalForResource = 60

        // Upload session with longer timeout
        let uploadConfiguration = URLSessionConfiguration.default
        uploadConfiguration.timeoutIntervalForRequest = AppConfig.uploadTimeout
        uploadConfiguration.timeoutIntervalForResource = 120

        self.session = URLSession(configuration: configuration)
        self.uploadSession = URLSession(configuration: uploadConfiguration)
        self.baseURL = AppConfig.apiBaseURL
        self.keychainManager = KeychainManager.shared
    }

    // MARK: - Request Methods

    /// Generic GET request
    func get<T: Codable>(
        _ endpoint: String,
        parameters: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .get,
            parameters: parameters,
            requiresAuth: requiresAuth
        )
    }

    /// Generic POST request
    func post<T: Codable>(
        _ endpoint: String,
        parameters: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .post,
            parameters: parameters,
            requiresAuth: requiresAuth
        )
    }

    /// Generic PUT request
    func put<T: Codable>(
        _ endpoint: String,
        parameters: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .put,
            parameters: parameters,
            requiresAuth: requiresAuth
        )
    }

    /// Generic PATCH request
    func patch<T: Codable>(
        _ endpoint: String,
        parameters: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .patch,
            parameters: parameters,
            requiresAuth: requiresAuth
        )
    }

    /// Generic DELETE request
    func delete<T: Codable>(
        _ endpoint: String,
        parameters: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .delete,
            parameters: parameters,
            requiresAuth: requiresAuth
        )
    }

    // MARK: - Connection Testing

    /// Test connection to the backend server
    /// - Returns: Tuple with success status and descriptive message
    func testConnection() async -> (success: Bool, message: String) {
        NSLog("🔍 Testing connection to backend server...")
        os_log("🔍 Testing connection to backend server...", log: logger, type: .info)

        guard let url = URL(string: baseURL + APIEndpoint.health) else {
            let errorMsg = "Invalid base URL: \(baseURL)"
            NSLog("❌ Connection test failed: \(errorMsg)")
            os_log("❌ Connection test failed: %{public}@", log: logger, type: .error, errorMsg)
            return (false, errorMsg)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        NSLog("🌐 Testing URL: \(url.absoluteString)")
        os_log("🌐 Testing URL: %{public}@", log: logger, type: .info, url.absoluteString)

        do {
            let startTime = Date()
            let (data, response) = try await session.data(for: request)
            let duration = Date().timeIntervalSince(startTime)

            guard let httpResponse = response as? HTTPURLResponse else {
                let errorMsg = "Invalid response type from server"
                NSLog("❌ \(errorMsg)")
                os_log("❌ %{public}@", log: logger, type: .error, errorMsg)
                return (false, errorMsg)
            }

            NSLog("📊 Connection test response:")
            NSLog("   Status Code: \(httpResponse.statusCode)")
            NSLog("   Response Time: \(String(format: "%.2f", duration * 1000))ms")
            NSLog("   Data Size: \(data.count) bytes")

            os_log("📊 Status: %{public}d, Time: %.2fms, Size: %{public}d bytes",
                   log: logger, type: .info,
                   httpResponse.statusCode, duration * 1000, data.count)

            if let responseString = String(data: data, encoding: .utf8) {
                NSLog("   Response: \(responseString)")
                os_log("   Response: %{public}@", log: logger, type: .info, responseString)
            }

            if (200...299).contains(httpResponse.statusCode) {
                let successMsg = "Successfully connected to server (Status: \(httpResponse.statusCode), Time: \(String(format: "%.0f", duration * 1000))ms)"
                NSLog("✅ \(successMsg)")
                os_log("✅ %{public}@", log: logger, type: .info, successMsg)
                return (true, successMsg)
            } else {
                let errorMsg = "Server returned status code \(httpResponse.statusCode)"
                NSLog("⚠️ \(errorMsg)")
                os_log("⚠️ %{public}@", log: logger, type: .error, errorMsg)
                return (false, errorMsg)
            }

        } catch {
            let nsError = error as NSError
            var errorMsg = "Connection failed: "

            NSLog("❌ Connection test error:")
            NSLog("   Domain: \(nsError.domain)")
            NSLog("   Code: \(nsError.code)")
            NSLog("   Description: \(nsError.localizedDescription)")

            os_log("❌ Connection error - Domain: %{public}@, Code: %{public}d",
                   log: logger, type: .error, nsError.domain, nsError.code)

            // Provide specific error messages based on error codes
            switch nsError.code {
            case NSURLErrorTimedOut:
                errorMsg += "Request timed out. Server may be slow or unreachable."
            case NSURLErrorCannotConnectToHost:
                errorMsg += "Cannot connect to \(baseURL). Server may be offline."
            case NSURLErrorCannotFindHost:
                errorMsg += "Cannot find host. Check server address: \(baseURL)"
            case NSURLErrorNotConnectedToInternet:
                errorMsg += "No internet connection. Check network settings."
            case NSURLErrorSecureConnectionFailed:
                errorMsg += "SSL/TLS connection failed. Certificate may be invalid."
            case NSURLErrorNetworkConnectionLost:
                errorMsg += "Network connection lost during request."
            case NSURLErrorDNSLookupFailed:
                errorMsg += "DNS lookup failed. Check server hostname."
            default:
                errorMsg += "\(nsError.localizedDescription) (Code: \(nsError.code))"
            }

            if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                NSLog("   Underlying Error: \(underlyingError.localizedDescription)")
                os_log("   Underlying: %{public}@", log: logger, type: .error, underlyingError.localizedDescription)
            }

            NSLog("❌ \(errorMsg)")
            os_log("❌ %{public}@", log: logger, type: .error, errorMsg)

            return (false, errorMsg)
        }
    }

    // MARK: - Core Request Method

    private func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        requiresAuth: Bool
    ) async throws -> T {
        // Build URL
        var urlString = baseURL + endpoint

        // Add query parameters for GET requests
        if method == .get, let parameters = parameters {
            var components = URLComponents(string: urlString)
            components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            urlString = components?.url?.absoluteString ?? urlString
        }

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add auth token if required
        if requiresAuth {
            guard let token = keychainManager.getAccessToken() else {
                throw APIError.unauthorized
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add body for POST/PUT/PATCH
        if method != .get, let parameters = parameters {
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        }

        // Make request
        do {
            NSLog("🌐 Request: \(method.rawValue) \(urlString)")
            os_log("🌐 Request: %{public}@ %{public}@", log: logger, type: .info, method.rawValue, urlString)
            if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
                NSLog("📤 Request body: \(bodyString)")
                os_log("📤 Request body: %{public}@", log: logger, type: .info, bodyString)
            }

            let (data, response) = try await session.data(for: request)

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            NSLog("📊 Response status: \(statusCode)")
            NSLog("📦 Response data size: \(data.count) bytes")
            os_log("📊 Response status: %{public}d", log: logger, type: .info, statusCode)
            os_log("📦 Response data size: %{public}d bytes", log: logger, type: .info, data.count)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(NSError(domain: "Invalid response", code: 0))
            }

            // Handle errors
            if httpResponse.statusCode == 401 {
                // Log the 401 response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔴 401 Response (requiresAuth=\(requiresAuth)): \(responseString)")
                }

                // Only clear keychain for authenticated endpoints
                // Don't clear for login/register endpoints
                if requiresAuth {
                    print("🔴 401 on authenticated endpoint - clearing keychain")
                    keychainManager.clearAll()
                    throw APIError.unauthorized
                } else {
                    print("🔴 401 on unauthenticated endpoint - parsing error message")
                    // For unauthenticated endpoints (like login), parse the actual error
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        let errorMsg = errorResponse.error ?? errorResponse.message ?? "Authentication failed"
                        print("🔴 Parsed error message: \(errorMsg)")
                        throw APIError.serverError(errorMsg)
                    } else {
                        print("🔴 Failed to parse error response, raw data: \(String(describing: String(data: data, encoding: .utf8)))")
                        throw APIError.serverError("Authentication failed")
                    }
                }
            }

            if httpResponse.statusCode >= 400 {
                // Client or server error
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw APIError.serverError(
                        errorResponse.error ?? errorResponse.message ?? "Request failed"
                    )
                } else {
                    throw APIError.serverError("Request failed with status \(httpResponse.statusCode)")
                }
            }

            // Decode response
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            // Custom date strategy to handle ISO8601 with milliseconds and 'Z' timezone
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                var dateString = try container.decode(String.self)

                // Replace 'Z' with '+0000' for DateFormatter compatibility
                if dateString.hasSuffix("Z") {
                    dateString = dateString.replacingOccurrences(of: "Z", with: "+0000")
                }

                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)

                // Try ISO8601 with milliseconds
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                if let date = formatter.date(from: dateString) {
                    return date
                }

                // Fallback to ISO8601 without milliseconds
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                if let date = formatter.date(from: dateString) {
                    return date
                }

                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
            }

            do {
                // Debug: Print response data
                if let jsonString = String(data: data, encoding: .utf8) {
                    NSLog("📥 Response data: \(jsonString)")
                    os_log("📥 Response data: %{public}@", log: logger, type: .info, jsonString)
                }
                let decoded = try decoder.decode(T.self, from: data)
                NSLog("✅ Successfully decoded response")
                return decoded
            } catch {
                NSLog("❌ Decoding error: \(error)")
                NSLog("❌ Error details: \(error.localizedDescription)")
                os_log("❌ Decoding error: %{public}@", log: logger, type: .error, error.localizedDescription)
                if let jsonString = String(data: data, encoding: .utf8) {
                    NSLog("📄 Raw data: \(jsonString)")
                    os_log("📄 Raw data: %{public}@", log: logger, type: .error, jsonString)
                }
                throw APIError.decodingError(error)
            }

        } catch let error as APIError {
            throw error
        } catch {
            // Enhanced network error logging
            let nsError = error as NSError
            NSLog("❌ NETWORK ERROR DETAILS:")
            NSLog("   Domain: \(nsError.domain)")
            NSLog("   Code: \(nsError.code)")
            NSLog("   Description: \(nsError.localizedDescription)")
            NSLog("   Failure Reason: \(nsError.localizedFailureReason ?? "N/A")")
            NSLog("   Recovery Suggestion: \(nsError.localizedRecoverySuggestion ?? "N/A")")

            os_log("❌ NETWORK ERROR - Domain: %{public}@, Code: %{public}d, Description: %{public}@",
                   log: logger, type: .error,
                   nsError.domain, nsError.code, nsError.localizedDescription)

            if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                NSLog("   Underlying Error Domain: \(underlyingError.domain)")
                NSLog("   Underlying Error Code: \(underlyingError.code)")
                NSLog("   Underlying Error Description: \(underlyingError.localizedDescription)")
                os_log("   Underlying Error: %{public}@ (Code: %{public}d)",
                       log: logger, type: .error,
                       underlyingError.domain, underlyingError.code)
            }

            if let url = nsError.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
                NSLog("   Failing URL: \(url.absoluteString)")
                os_log("   Failing URL: %{public}@", log: logger, type: .error, url.absoluteString)
            }

            throw APIError.networkError(error)
        }
    }

    // MARK: - Multipart File Upload

    /// Upload audio file with multipart form data
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - fileData: Audio data to upload
    ///   - fileName: Name of the file
    ///   - mimeType: MIME type (e.g., "audio/m4a", "audio/wav")
    ///   - parameters: Additional form parameters
    ///   - requiresAuth: Whether authentication is required
    /// - Returns: Decoded response of type T
    func uploadAudio<T: Codable>(
        _ endpoint: String,
        fileData: Data,
        fileName: String,
        mimeType: String = "audio/m4a",
        parameters: [String: String]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        return try await uploadFile(
            endpoint,
            fileData: fileData,
            fileName: fileName,
            mimeType: mimeType,
            fieldName: "audio",
            parameters: parameters,
            requiresAuth: requiresAuth
        )
    }

    /// Upload file with multipart form data
    /// - Parameters:
    ///   - endpoint: API endpoint
    ///   - fileData: File data to upload
    ///   - fileName: Name of the file
    ///   - mimeType: MIME type of the file
    ///   - fieldName: Form field name for the file (default: "file")
    ///   - parameters: Additional form parameters
    ///   - requiresAuth: Whether authentication is required
    /// - Returns: Decoded response of type T
    func uploadFile<T: Codable>(
        _ endpoint: String,
        fileData: Data,
        fileName: String,
        mimeType: String,
        fieldName: String = "file",
        parameters: [String: String]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)

        // Add other parameters
        if let parameters = parameters {
            for (key, value) in parameters {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = body

        // Add auth token
        if requiresAuth {
            guard let token = keychainManager.getAccessToken() else {
                throw APIError.unauthorized
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Make request with upload session (longer timeout)
        do {
            NSLog("🎵 Uploading file: \(fileName) (\(fileData.count) bytes)")
            os_log("🎵 Uploading file: %{public}@ (%{public}d bytes)",
                   log: logger, type: .info, fileName, fileData.count)

            let (data, response) = try await uploadSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(NSError(domain: "Invalid response", code: 0))
            }

            NSLog("📊 Upload response status: \(httpResponse.statusCode)")
            os_log("📊 Upload response status: %{public}d", log: logger, type: .info, httpResponse.statusCode)

            if httpResponse.statusCode == 401 {
                if requiresAuth {
                    keychainManager.clearAll()
                }
                throw APIError.unauthorized
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw APIError.uploadFailed(errorResponse.error ?? errorResponse.message ?? "Upload failed")
                } else {
                    throw APIError.uploadFailed("Upload failed with status \(httpResponse.statusCode)")
                }
            }

            // Decode response
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            if let jsonString = String(data: data, encoding: .utf8) {
                NSLog("📥 Upload response: \(jsonString)")
                os_log("📥 Upload response: %{public}@", log: logger, type: .info, jsonString)
            }

            let decoded = try decoder.decode(T.self, from: data)
            NSLog("✅ Successfully uploaded and decoded response")
            return decoded

        } catch let error as APIError {
            throw error
        } catch {
            NSLog("❌ Upload error: \(error.localizedDescription)")
            os_log("❌ Upload error: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw APIError.networkError(error)
        }
    }
}

// MARK: - Error Response Models

struct ErrorResponse: Codable {
    let error: String?
    let message: String?
    let code: String?
    let details: [String: String]?

    enum CodingKeys: String, CodingKey {
        case error, message, code, details
    }
}

// MARK: - Success Response Wrapper

struct SuccessResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case success, data, message
    }
}
