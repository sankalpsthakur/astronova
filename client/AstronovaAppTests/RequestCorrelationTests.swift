import XCTest
@testable import AstronovaApp

final class RequestCorrelationTests: XCTestCase {
    override func setUpWithError() throws {
        PortfolioAnalytics.shared._resetForTests()
        RequestCaptureURLProtocol.handler = nil
    }

    override func tearDownWithError() throws {
        PortfolioAnalytics.shared._resetForTests()
        RequestCaptureURLProtocol.handler = nil
    }

    func testTypedRequestPropagatesOneRequestIDAndLogsOnlyAllowListedFields() async throws {
        let requestID = "client-request-0001"
        let jwt = "secret.jwt.value"
        let privateText = "my private oracle question"
        let privateBirthDate = "1990-01-15"
        var generationCount = 0
        let client = makeClient(requestID: requestID) { generationCount += 1 }
        client.setJWTToken(jwt)

        var networkProperties: [String: String]?
        PortfolioAnalytics.shared.testEventSink = { event, properties in
            if event == .networkRequest { networkProperties = properties }
        }
        RequestCaptureURLProtocol.handler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Request-ID"), requestID)
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(jwt)")
            return Self.response(for: request, requestID: requestID, body: #"{"status":"ok"}"#)
        }

        let body = SensitiveRequest(birthDate: privateBirthDate, text: privateText)
        _ = try await client.request(
            endpoint: "/api/v1/chart/generate?person=private-name",
            method: .POST,
            body: body,
            responseType: HealthResponse.self
        )

        XCTAssertEqual(networkProperties, [
            "request_id": requestID,
            "endpoint": "/api/v1/chart/generate",
            "status_code": "200",
            "method": "POST"
        ])
        XCTAssertEqual(generationCount, 1, "Each API request must generate its correlation ID exactly once")
        let logged = String(describing: networkProperties)
        XCTAssertFalse(logged.contains(jwt))
        XCTAssertFalse(logged.contains(privateText))
        XCTAssertFalse(logged.contains(privateBirthDate))
        XCTAssertFalse(logged.contains("private-name"))
    }

    func testRawDataRequestUsesEchoedRequestIDAndRedactedRoute() async throws {
        let requestID = "client-request-0002"
        let client = makeClient(requestID: requestID)
        var networkProperties: [String: String]?
        PortfolioAnalytics.shared.testEventSink = { event, properties in
            if event == .networkRequest { networkProperties = properties }
        }
        RequestCaptureURLProtocol.handler = { request in
            Self.response(for: request, requestID: requestID, body: #"{"ok":true}"#)
        }

        _ = try await client.requestData(
            endpoint: "/api/v1/reports/12345?text=private-user-text",
            method: .GET,
            body: nil
        )

        XCTAssertEqual(networkProperties?["request_id"], requestID)
        XCTAssertEqual(networkProperties?["endpoint"], "/api/v1/reports/:id")
        XCTAssertFalse(String(describing: networkProperties).contains("private-user-text"))
    }

    func testMalformedResponseRequestIDIsNotCopiedToTelemetry() throws {
        let fallback = "client-request-0003"
        let response = try XCTUnwrap(HTTPURLResponse(
            url: URL(string: "https://example.test/health")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["X-Request-ID": "Bearer secret.jwt.value"]
        ))
        XCTAssertEqual(NetworkClient.responseRequestId(from: response, fallback: fallback), fallback)
    }

    func testUnicodeResponseRequestIDIsNotCopiedToTelemetry() throws {
        let fallback = "client-request-0004"
        let response = try XCTUnwrap(HTTPURLResponse(
            url: URL(string: "https://example.test/health")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["X-Request-ID": "client-réquest-0004"]
        ))
        XCTAssertEqual(NetworkClient.responseRequestId(from: response, fallback: fallback), fallback)
    }

    private func makeClient(requestID: String, onGenerate: (() -> Void)? = nil) -> NetworkClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RequestCaptureURLProtocol.self]
        return NetworkClient(
            baseURL: "https://example.test",
            session: URLSession(configuration: configuration),
            requestIdGenerator: {
                onGenerate?()
                return requestID
            }
        )
    }

    private static func response(
        for request: URLRequest,
        requestID: String,
        body: String
    ) -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["X-Request-ID": requestID]
        )!
        return (response, Data(body.utf8))
    }
}

private struct SensitiveRequest: Encodable {
    let birthDate: String
    let text: String
}

private final class RequestCaptureURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            let (response, data) = try XCTUnwrap(Self.handler)(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
