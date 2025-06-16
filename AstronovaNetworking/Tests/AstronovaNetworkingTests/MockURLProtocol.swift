import Foundation

/// Mock URLProtocol for testing network requests
class MockURLProtocol: URLProtocol {
    /// Dictionary to hold mocked responses
    static nonisolated(unsafe) var mockResponses: [URL: MockResponse] = [:]
    
    /// Mock response structure
    struct MockResponse {
        let data: Data?
        let response: HTTPURLResponse?
        let error: Error?
        let delay: TimeInterval?
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let url = request.url,
              let mockResponse = MockURLProtocol.mockResponses[url] else {
            // Default to 404 if no mock response is configured
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data())
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        
        // Simulate network delay if specified
        let delay = mockResponse.delay ?? 0
        let client = self.client
        let protocolSelf = self
        
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            // Return error if specified
            if let error = mockResponse.error {
                client?.urlProtocol(protocolSelf, didFailWithError: error)
                return
            }
            
            // Return response
            if let response = mockResponse.response {
                client?.urlProtocol(protocolSelf, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            // Return data if specified
            if let data = mockResponse.data {
                client?.urlProtocol(protocolSelf, didLoad: data)
            }
            
            client?.urlProtocolDidFinishLoading(protocolSelf)
        }
    }
    
    override func stopLoading() {
        // Nothing to do
    }
    
    /// Helper method to add mock responses
    static func addMockResponse(for url: URL, data: Data?, response: HTTPURLResponse?, error: Error? = nil, delay: TimeInterval? = nil) {
        mockResponses[url] = MockResponse(data: data, response: response, error: error, delay: delay)
    }
    
    /// Helper method to clear all mock responses
    static func clearMocks() {
        mockResponses.removeAll()
    }
    
    /// Helper method to create HTTP response
    static func createHTTPResponse(url: URL, statusCode: Int, headers: [String: String]? = nil) -> HTTPURLResponse? {
        return HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )
    }
}