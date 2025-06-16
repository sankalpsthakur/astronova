import Foundation
import OSLog

// MARK: - Simple Logging for NetworkClient
private let networkLogger = Logger(subsystem: "com.astronova.app", category: "networking")

// MARK: - Simple Configuration for NetworkClient
private struct SimpleConfiguration {
    static let baseURL: String = {
        #if DEBUG
        return "http://127.0.0.1:8080"
        #else
        return "https://api.astronova.app"
        #endif
    }()
    
    static let timeout: TimeInterval = {
        #if DEBUG
        return 30.0
        #else
        return 15.0
        #endif
    }()
}

// Temporary protocol until services are added to project
protocol ConfigurationProtocol {
    var baseURL: String { get }
    var timeout: TimeInterval { get }
}

// Temporary service until services are added to project
class ConfigurationService: ConfigurationProtocol {
    static let shared = ConfigurationService()
    
    var baseURL: String { SimpleConfiguration.baseURL }
    var timeout: TimeInterval { SimpleConfiguration.timeout }
    
    private init() {}
}

/// NetworkError enum for handling API errors
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidRequest
    case noData
    case decodingError
    case serverError(Int)
    case networkError(Error)
    
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
        case .serverError(let code):
            return "Server error: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
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
    private let configuration: ConfigurationProtocol
    
    convenience init() {
        self.init(baseURL: nil, session: nil, configuration: nil)
    }
    
    public init(baseURL: String? = nil, session: URLSession? = nil, configuration: ConfigurationProtocol? = nil) {
        self.configuration = configuration ?? ConfigurationService.shared
        
        // Use provided baseURL or configuration service
        if let baseURL = baseURL {
            self.baseURL = baseURL
        } else {
            self.baseURL = self.configuration.baseURL
        }
        
        if let session = session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = self.configuration.timeout
            config.timeoutIntervalForResource = self.configuration.timeout * 2
            self.session = URLSession(configuration: config)
        }
        
        networkLogger.debug("Initialized NetworkClient with baseURL: \(self.baseURL)")
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
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw NetworkError.serverError(httpResponse.statusCode)
            }
            
            guard !data.isEmpty else {
                throw NetworkError.noData
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(responseType, from: data)
            } catch {
                networkLogger.error("Network error: \(error.localizedDescription)")
                networkLogger.debug("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to convert to string")")
                throw NetworkError.decodingError
            }
        } catch {
            if error is NetworkError {
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
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw NetworkError.serverError(httpResponse.statusCode)
            }
            
            guard !data.isEmpty else {
                throw NetworkError.noData
            }
            
            return data
        } catch {
            if error is NetworkError {
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