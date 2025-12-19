import Foundation

/// NetworkError enum for handling API errors
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidRequest
    case noData
    case decodingError
    case serverError(Int, String?)
    case networkError(Error)
    case authenticationFailed(String?)
    case tokenExpired
    case offline
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidRequest:
            return "Invalid request"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .serverError(let code, let message):
            if let message = message {
                return "Server error (\(code)): \(message)"
            }
            return "Server error: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .authenticationFailed(let message):
            return message ?? "Authentication failed"
        case .tokenExpired:
            return "Your session has expired. Please sign in again."
        case .offline:
            return "No internet connection. Some features may be limited."
        case .timeout:
            return "Request timed out. Please try again."
        }
    }
    
    var isRecoverable: Bool {
        switch self {
        case .networkError, .timeout, .offline:
            return true
        case .serverError(let code, _):
            return code >= 500 // Server errors are potentially recoverable
        default:
            return false
        }
    }
    
    var requiresReauthentication: Bool {
        switch self {
        case .authenticationFailed, .tokenExpired:
            return true
        case .serverError(let code, _):
            return code == 401
        default:
            return false
        }
    }
}

/// HTTP methods supported by the API
enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
}

// MARK: - Network Client Protocol

protocol NetworkClientProtocol {
    func healthCheck() async throws -> HealthResponse
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable?,
        responseType: T.Type
    ) async throws -> T
    func request<T: Codable>(
        endpoint: String,
        responseType: T.Type
    ) async throws -> T
    func requestData(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable?
    ) async throws -> Data
}

/// NetworkClient handles all HTTP communication with the backend
class NetworkClient: NetworkClientProtocol {
    static let shared = NetworkClient()
    
    private let baseURL: String
    private let session: URLSession
    private var jwtToken: String?
    private let userIdKey = "client_user_id"
    private var cachedUserId: String?
    
    public init(baseURL: String? = nil, session: URLSession? = nil) {
        // Prefer explicit param, otherwise fall back to AppConfig
        self.baseURL = baseURL ?? AppConfig.shared.apiBaseURL
        
        if let session = session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 10
            config.timeoutIntervalForResource = 30
            self.session = URLSession(configuration: config)
        }
    }

    private func getOrCreateUserId() -> String {
        if let cachedUserId {
            return cachedUserId
        }

        if let existing = UserDefaults.standard.string(forKey: userIdKey), !existing.isEmpty {
            cachedUserId = existing
            return existing
        }

        let created = UUID().uuidString
        UserDefaults.standard.set(created, forKey: userIdKey)
        cachedUserId = created
        return created
    }
    
    /// Generic method to make API requests
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Encodable? = nil,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(getOrCreateUserId(), forHTTPHeaderField: "X-User-Id")
        
        // Add JWT token if available
        if let jwtToken = jwtToken {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        
        // Add body if provided
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw NetworkError.networkError(error)
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.networkError(URLError(.badServerResponse))
            }
            
            // Handle different HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                break // Success
            case 401:
                // Try to extract error message from response
                let errorMessage = extractErrorMessage(from: data)
                if errorMessage?.contains("expired") == true {
                    throw NetworkError.tokenExpired
                } else {
                    throw NetworkError.authenticationFailed(errorMessage)
                }
            case 400...499:
                let errorMessage = extractErrorMessage(from: data)
                throw NetworkError.serverError(httpResponse.statusCode, errorMessage)
            case 500...599:
                let errorMessage = extractErrorMessage(from: data)
                throw NetworkError.serverError(httpResponse.statusCode, errorMessage)
            default:
                throw NetworkError.serverError(httpResponse.statusCode, nil)
            }
            
            guard !data.isEmpty else {
                throw NetworkError.noData
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(responseType, from: data)
            } catch {
                #if DEBUG
                // Only log decoding errors in debug builds, never response data
                debugPrint("[NetworkClient] Decoding error for \(responseType): \(error.localizedDescription)")
                #endif
                throw NetworkError.decodingError
            }
        } catch {
            // Handle network-specific errors
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    throw NetworkError.offline
                case .timedOut:
                    throw NetworkError.timeout
                default:
                    throw NetworkError.networkError(urlError)
                }
            } else if error is NetworkError {
                throw error
            } else {
                throw NetworkError.networkError(error)
            }
        }
    }
    
    /// Convenience method for GET requests without body
    func request<T: Codable>(
        endpoint: String,
        responseType: T.Type
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .GET,
            body: nil,
            responseType: responseType
        )
    }
    
    /// Generic method to make raw API requests returning Data
    func requestData(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Encodable? = nil
    ) async throws -> Data {
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add JWT token if available
        if let jwtToken = jwtToken {
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        }
        
        // Add body if provided
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw NetworkError.networkError(error)
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.networkError(URLError(.badServerResponse))
            }
            
            // Handle different HTTP status codes
            switch httpResponse.statusCode {
            case 200...299:
                break // Success
            case 401:
                // Try to extract error message from response
                let errorMessage = extractErrorMessage(from: data)
                if errorMessage?.contains("expired") == true {
                    throw NetworkError.tokenExpired
                } else {
                    throw NetworkError.authenticationFailed(errorMessage)
                }
            case 400...499:
                let errorMessage = extractErrorMessage(from: data)
                throw NetworkError.serverError(httpResponse.statusCode, errorMessage)
            case 500...599:
                let errorMessage = extractErrorMessage(from: data)
                throw NetworkError.serverError(httpResponse.statusCode, errorMessage)
            default:
                throw NetworkError.serverError(httpResponse.statusCode, nil)
            }
            
            guard !data.isEmpty else {
                throw NetworkError.noData
            }
            
            return data
        } catch {
            // Handle network-specific errors
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    throw NetworkError.offline
                case .timedOut:
                    throw NetworkError.timeout
                default:
                    throw NetworkError.networkError(urlError)
                }
            } else if error is NetworkError {
                throw error
            } else {
                throw NetworkError.networkError(error)
            }
        }
    }
    
    /// Check if the backend is healthy
    func healthCheck() async throws -> HealthResponse {
        return try await request(
            endpoint: "/health",
            responseType: HealthResponse.self
        )
    }
    
    /// Set JWT token for authenticated requests
    func setJWTToken(_ token: String?) {
        self.jwtToken = token
    }
    
    /// Extract error message from response data
    private func extractErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        // Try different common error message keys
        if let message = json["message"] as? String {
            return message
        }
        if let error = json["error"] as? String {
            return error
        }
        if let detail = json["detail"] as? String {
            return detail
        }
        
        return nil
    }
}

/// Health check response model
struct HealthResponse: Codable {
    let status: String
    let message: String?
    
    init(status: String, message: String? = nil) {
        self.status = status
        self.message = message
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(String.self, forKey: .status)
        message = try container.decodeIfPresent(String.self, forKey: .message)
    }
    
    private enum CodingKeys: String, CodingKey {
        case status, message
    }
}
