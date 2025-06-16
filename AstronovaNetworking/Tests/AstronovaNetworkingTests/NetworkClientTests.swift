import XCTest
@testable import AstronovaNetworking

final class NetworkClientTests: XCTestCase {
    var networkClient: NetworkClient!
    var mockSession: URLSession!
    
    override func setUp() {
        super.setUp()
        
        // Configure mock URLSession
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)
        
        // Create NetworkClient with mock session
        networkClient = NetworkClient(
            baseURL: "https://test.api.com",
            session: mockSession
        )
        
        // Clear any existing mocks
        MockURLProtocol.clearMocks()
    }
    
    override func tearDown() {
        MockURLProtocol.clearMocks()
        networkClient = nil
        mockSession = nil
        super.tearDown()
    }
    
    // MARK: - 4xx Client Error Tests
    
    func testRequest_400_BadRequest() async throws {
        // Arrange
        let url = URL(string: "https://test.api.com/test")!
        let response = MockURLProtocol.createHTTPResponse(url: url, statusCode: 400)
        let errorData = """
        {
            "error": "Bad Request",
            "details": [
                {
                    "field": "birthDate",
                    "message": "Invalid date format",
                    "code": "INVALID_FORMAT"
                }
            ],
            "code": "BAD_REQUEST"
        }
        """.data(using: .utf8)
        
        MockURLProtocol.addMockResponse(for: url, data: errorData, response: response)
        
        // Act & Assert
        do {
            let _: HealthResponse = try await networkClient.request(
                endpoint: "/test",
                responseType: HealthResponse.self
            )
            XCTFail("Expected NetworkError.serverError(400) to be thrown")
        } catch let error as NetworkError {
            switch error {
            case .serverError(let code):
                XCTAssertEqual(code, 400)
            default:
                XCTFail("Expected NetworkError.serverError(400), got \(error)")
            }
        }
    }
    
    func testRequest_401_Unauthorized() async throws {
        // Arrange
        let url = URL(string: "https://test.api.com/protected")!
        let response = MockURLProtocol.createHTTPResponse(url: url, statusCode: 401)
        let errorData = """
        {
            "error": "Unauthorized",
            "code": "UNAUTHORIZED"
        }
        """.data(using: .utf8)
        
        MockURLProtocol.addMockResponse(for: url, data: errorData, response: response)
        
        // Act & Assert
        do {
            let _: HealthResponse = try await networkClient.request(
                endpoint: "/protected",
                responseType: HealthResponse.self
            )
            XCTFail("Expected NetworkError.serverError(401) to be thrown")
        } catch let error as NetworkError {
            switch error {
            case .serverError(let code):
                XCTAssertEqual(code, 401)
            default:
                XCTFail("Expected NetworkError.serverError(401), got \(error)")
            }
        }
    }
    
    func testRequest_403_Forbidden() async throws {
        // Arrange
        let url = URL(string: "https://test.api.com/admin")!
        let response = MockURLProtocol.createHTTPResponse(url: url, statusCode: 403)
        let errorData = """
        {
            "error": "Forbidden",
            "code": "FORBIDDEN"
        }
        """.data(using: .utf8)
        
        MockURLProtocol.addMockResponse(for: url, data: errorData, response: response)
        
        // Act & Assert
        do {
            let _: HealthResponse = try await networkClient.request(
                endpoint: "/admin",
                responseType: HealthResponse.self
            )
            XCTFail("Expected NetworkError.serverError(403) to be thrown")
        } catch let error as NetworkError {
            switch error {
            case .serverError(let code):
                XCTAssertEqual(code, 403)
            default:
                XCTFail("Expected NetworkError.serverError(403), got \(error)")
            }
        }
    }
    
    func testRequest_404_NotFound() async throws {
        // Arrange
        let url = URL(string: "https://test.api.com/nonexistent")!
        let response = MockURLProtocol.createHTTPResponse(url: url, statusCode: 404)
        let errorData = """
        {
            "error": "Not Found",
            "code": "NOT_FOUND"
        }
        """.data(using: .utf8)
        
        MockURLProtocol.addMockResponse(for: url, data: errorData, response: response)
        
        // Act & Assert
        do {
            let _: HealthResponse = try await networkClient.request(
                endpoint: "/nonexistent",
                responseType: HealthResponse.self
            )
            XCTFail("Expected NetworkError.serverError(404) to be thrown")
        } catch let error as NetworkError {
            switch error {
            case .serverError(let code):
                XCTAssertEqual(code, 404)
            default:
                XCTFail("Expected NetworkError.serverError(404), got \(error)")
            }
        }
    }
    
    func testRequest_422_UnprocessableEntity() async throws {
        // Arrange
        let url = URL(string: "https://test.api.com/validation")!
        let response = MockURLProtocol.createHTTPResponse(url: url, statusCode: 422)
        let errorData = """
        {
            "error": "Validation failed",
            "details": [
                {
                    "field": "email",
                    "message": "Invalid email format",
                    "code": "INVALID_EMAIL"
                },
                {
                    "field": "birthTime",
                    "message": "Birth time is required",
                    "code": "REQUIRED_FIELD"
                }
            ],
            "code": "VALIDATION_ERROR"
        }
        """.data(using: .utf8)
        
        MockURLProtocol.addMockResponse(for: url, data: errorData, response: response)
        
        // Act & Assert
        do {
            let _: HealthResponse = try await networkClient.request(
                endpoint: "/validation",
                responseType: HealthResponse.self
            )
            XCTFail("Expected NetworkError.serverError(422) to be thrown")
        } catch let error as NetworkError {
            switch error {
            case .serverError(let code):
                XCTAssertEqual(code, 422)
            default:
                XCTFail("Expected NetworkError.serverError(422), got \(error)")
            }
        }
    }
    
    func testRequest_429_TooManyRequests() async throws {
        // Arrange
        let url = URL(string: "https://test.api.com/ratelimited")!
        let response = MockURLProtocol.createHTTPResponse(
            url: url,
            statusCode: 429,
            headers: ["Retry-After": "60"]
        )
        let errorData = """
        {
            "error": "Too Many Requests",
            "code": "RATE_LIMITED"
        }
        """.data(using: .utf8)
        
        MockURLProtocol.addMockResponse(for: url, data: errorData, response: response)
        
        // Act & Assert
        do {
            let _: HealthResponse = try await networkClient.request(
                endpoint: "/ratelimited",
                responseType: HealthResponse.self
            )
            XCTFail("Expected NetworkError.serverError(429) to be thrown")
        } catch let error as NetworkError {
            switch error {
            case .serverError(let code):
                XCTAssertEqual(code, 429)
            default:
                XCTFail("Expected NetworkError.serverError(429), got \(error)")
            }
        }
    }
    
    // MARK: - 5xx Server Error Tests
    
    func testRequest_500_InternalServerError() async throws {
        // Arrange
        let url = URL(string: "https://test.api.com/crash")!
        let response = MockURLProtocol.createHTTPResponse(url: url, statusCode: 500)
        let errorData = """
        {
            "error": "Internal Server Error",
            "code": "INTERNAL_ERROR"
        }
        """.data(using: .utf8)
        
        MockURLProtocol.addMockResponse(for: url, data: errorData, response: response)
        
        // Act & Assert
        do {
            let _: HealthResponse = try await networkClient.request(
                endpoint: "/crash",
                responseType: HealthResponse.self
            )
            XCTFail("Expected NetworkError.serverError(500) to be thrown")
        } catch let error as NetworkError {
            switch error {
            case .serverError(let code):
                XCTAssertEqual(code, 500)
            default:
                XCTFail("Expected NetworkError.serverError(500), got \(error)")
            }
        }
    }
    
    func testRequest_502_BadGateway() async throws {
        // Arrange
        let url = URL(string: "https://test.api.com/gateway")!
        let response = MockURLProtocol.createHTTPResponse(url: url, statusCode: 502)
        let errorData = """
        {
            "error": "Bad Gateway",
            "code": "BAD_GATEWAY"
        }
        """.data(using: .utf8)
        
        MockURLProtocol.addMockResponse(for: url, data: errorData, response: response)
        
        // Act & Assert
        do {
            let _: HealthResponse = try await networkClient.request(
                endpoint: "/gateway",
                responseType: HealthResponse.self
            )
            XCTFail("Expected NetworkError.serverError(502) to be thrown")
        } catch let error as NetworkError {
            switch error {
            case .serverError(let code):
                XCTAssertEqual(code, 502)
            default:
                XCTFail("Expected NetworkError.serverError(502), got \(error)")
            }
        }
    }
    
    func testRequest_503_ServiceUnavailable() async throws {
        // Arrange
        let url = URL(string: "https://test.api.com/maintenance")!
        let response = MockURLProtocol.createHTTPResponse(
            url: url,
            statusCode: 503,
            headers: ["Retry-After": "3600"]
        )
        let errorData = """
        {
            "error": "Service Unavailable",
            "code": "MAINTENANCE"
        }
        """.data(using: .utf8)
        
        MockURLProtocol.addMockResponse(for: url, data: errorData, response: response)
        
        // Act & Assert
        do {
            let _: HealthResponse = try await networkClient.request(
                endpoint: "/maintenance",
                responseType: HealthResponse.self
            )
            XCTFail("Expected NetworkError.serverError(503) to be thrown")
        } catch let error as NetworkError {
            switch error {
            case .serverError(let code):
                XCTAssertEqual(code, 503)
            default:
                XCTFail("Expected NetworkError.serverError(503), got \(error)")
            }
        }
    }
    
    func testRequest_504_GatewayTimeout() async throws {
        // Arrange
        let url = URL(string: "https://test.api.com/timeout")!
        let response = MockURLProtocol.createHTTPResponse(url: url, statusCode: 504)
        let errorData = """
        {
            "error": "Gateway Timeout",
            "code": "GATEWAY_TIMEOUT"
        }
        """.data(using: .utf8)
        
        MockURLProtocol.addMockResponse(for: url, data: errorData, response: response)
        
        // Act & Assert
        do {
            let _: HealthResponse = try await networkClient.request(
                endpoint: "/timeout",
                responseType: HealthResponse.self
            )
            XCTFail("Expected NetworkError.serverError(504) to be thrown")
        } catch let error as NetworkError {
            switch error {
            case .serverError(let code):
                XCTAssertEqual(code, 504)
            default:
                XCTFail("Expected NetworkError.serverError(504), got \(error)")
            }
        }
    }
    
    // MARK: - Edge Cases and Additional Error Scenarios
    
    func testRequest_EmptyResponse() async throws {
        // Arrange
        let url = URL(string: "https://test.api.com/empty")!
        let response = MockURLProtocol.createHTTPResponse(url: url, statusCode: 200)
        
        MockURLProtocol.addMockResponse(for: url, data: Data(), response: response)
        
        // Act & Assert
        do {
            let _: HealthResponse = try await networkClient.request(
                endpoint: "/empty",
                responseType: HealthResponse.self
            )
            XCTFail("Expected NetworkError.noData to be thrown")
        } catch let error as NetworkError {
            switch error {
            case .noData:
                // Expected
                break
            default:
                XCTFail("Expected NetworkError.noData, got \(error)")
            }
        }
    }
    
    func testRequest_MalformedJSON() async throws {
        // Arrange
        let url = URL(string: "https://test.api.com/malformed")!
        let response = MockURLProtocol.createHTTPResponse(url: url, statusCode: 200)
        let malformedData = "{ invalid json".data(using: .utf8)
        
        MockURLProtocol.addMockResponse(for: url, data: malformedData, response: response)
        
        // Act & Assert
        do {
            let _: HealthResponse = try await networkClient.request(
                endpoint: "/malformed",
                responseType: HealthResponse.self
            )
            XCTFail("Expected NetworkError.decodingError to be thrown")
        } catch let error as NetworkError {
            switch error {
            case .decodingError:
                // Expected
                break
            default:
                XCTFail("Expected NetworkError.decodingError, got \(error)")
            }
        }
    }
    
    func testRequest_NetworkError() async throws {
        // Arrange
        let url = URL(string: "https://test.api.com/network-error")!
        let networkError = URLError(.networkConnectionLost)
        
        MockURLProtocol.addMockResponse(for: url, data: nil, response: nil, error: networkError)
        
        // Act & Assert
        do {
            let _: HealthResponse = try await networkClient.request(
                endpoint: "/network-error",
                responseType: HealthResponse.self
            )
            XCTFail("Expected NetworkError.networkError to be thrown")
        } catch let error as NetworkError {
            switch error {
            case .networkError:
                // Expected
                break
            default:
                XCTFail("Expected NetworkError.networkError, got \(error)")
            }
        }
    }
    
    // MARK: - Success Case Tests
    
    func testRequest_SuccessfulResponse() async throws {
        // Arrange
        let url = URL(string: "https://test.api.com/health")!
        let response = MockURLProtocol.createHTTPResponse(url: url, statusCode: 200)
        let successData = """
        {
            "status": "healthy",
            "message": "Service is running normally"
        }
        """.data(using: .utf8)
        
        MockURLProtocol.addMockResponse(for: url, data: successData, response: response)
        
        // Act
        let result: HealthResponse = try await networkClient.request(
            endpoint: "/health",
            responseType: HealthResponse.self
        )
        
        // Assert
        XCTAssertEqual(result.status, "healthy")
        XCTAssertEqual(result.message, "Service is running normally")
    }
    
    // MARK: - POST Request Tests
    
    func testRequest_POST_WithBody_422Error() async throws {
        // Arrange
        let url = URL(string: "https://test.api.com/charts")!
        let response = MockURLProtocol.createHTTPResponse(url: url, statusCode: 422)
        let errorData = """
        {
            "error": "Validation failed",
            "details": [
                {
                    "field": "birthData.date",
                    "message": "Invalid date format",
                    "code": "INVALID_DATE"
                }
            ],
            "code": "VALIDATION_ERROR"
        }
        """.data(using: .utf8)
        
        MockURLProtocol.addMockResponse(for: url, data: errorData, response: response)
        
        let birthData = BirthData(
            name: "Test User",
            date: "invalid-date",
            time: "12:00",
            latitude: 40.7128,
            longitude: -74.0060,
            city: "New York",
            state: "NY",
            country: "USA",
            timezone: "America/New_York"
        )
        
        let chartRequest = ChartRequest(
            birthData: birthData,
            chartType: "natal",
            systems: ["western"]
        )
        
        // Act & Assert
        do {
            let _: ChartResponse = try await networkClient.request(
                endpoint: "/charts",
                method: .POST,
                body: chartRequest,
                responseType: ChartResponse.self
            )
            XCTFail("Expected NetworkError.serverError(422) to be thrown")
        } catch let error as NetworkError {
            switch error {
            case .serverError(let code):
                XCTAssertEqual(code, 422)
            default:
                XCTFail("Expected NetworkError.serverError(422), got \(error)")
            }
        }
    }
}