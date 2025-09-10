import Foundation

/// Service to prevent duplicate concurrent API requests
actor RequestDeduplicationService {
    static let shared = RequestDeduplicationService()
    
    private var pendingRequests: [String: Task<Data, Error>] = [:]
    
    private init() {}
    
    /// Execute a deduplicated request - if the same request is already in progress, returns the existing task
    func deduplicatedRequest(
        key: String,
        request: @escaping () async throws -> Data
    ) async throws -> Data {
        // Check if we already have a pending request for this key
        if let existingTask = pendingRequests[key] {
            return try await existingTask.value
        }
        
        // Create new task for this request
        let task = Task<Data, Error> {
            do {
                let result = try await request()
                // Remove from pending requests after completion
                pendingRequests.removeValue(forKey: key)
                return result
            } catch {
                // Remove from pending requests on error
                pendingRequests.removeValue(forKey: key)
                throw error
            }
        }
        
        // Store the task
        pendingRequests[key] = task
        
        return try await task.value
    }
    
    /// Cancel a pending request if it exists
    func cancelRequest(key: String) {
        if let task = pendingRequests[key] {
            task.cancel()
            pendingRequests.removeValue(forKey: key)
        }
    }
    
    /// Cancel all pending requests
    func cancelAllRequests() {
        for (_, task) in pendingRequests {
            task.cancel()
        }
        pendingRequests.removeAll()
    }
    
    /// Get count of pending requests (for debugging)
    func pendingRequestCount() -> Int {
        pendingRequests.count
    }
}

// MARK: - URLRequest Extension for Key Generation

extension URLRequest {
    /// Generate a unique key for request deduplication
    var deduplicationKey: String {
        var components: [String] = []
        
        // Add URL
        if let url = self.url?.absoluteString {
            components.append(url)
        }
        
        // Add HTTP method
        if let method = self.httpMethod {
            components.append(method)
        }
        
        // Add body hash if present
        if let body = self.httpBody {
            let bodyHash = body.base64EncodedString().prefix(50)
            components.append(String(bodyHash))
        }
        
        // Add important headers
        if let headers = self.allHTTPHeaderFields {
            // Only include headers that affect the response
            let importantHeaders = ["Authorization", "Accept", "Content-Type"]
            for header in importantHeaders {
                if let value = headers[header] {
                    components.append("\(header):\(value)")
                }
            }
        }
        
        return components.joined(separator: "|")
    }
}

// MARK: - NetworkClient Extension

extension NetworkClient {
    /// Make a deduplicated request that prevents concurrent duplicate calls
    func deduplicatedRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Encodable? = nil,
        responseType: T.Type
    ) async throws -> T {
        // Create the URL request to get the deduplication key
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        
        if let body = body {
            urlRequest.httpBody = try? JSONEncoder().encode(body)
        }
        
        let key = urlRequest.deduplicationKey
        
        // Use the deduplication service
        let data = try await RequestDeduplicationService.shared.deduplicatedRequest(key: key) {
            try await self.requestData(endpoint: endpoint, method: method, body: body)
        }
        
        // Decode the response
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(responseType, from: data)
    }
}