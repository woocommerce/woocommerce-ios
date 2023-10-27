import XCTest
@testable import Networking

final class SiteDiscoveryUseCaseTests: XCTestCase {

    let sampleSiteURL = "https://example.com"

    func test_findRootAPIEndpoint_returns_correct_link_for_root_endpoint() async throws {
        // Given
        let headers = ["Link": "<https://example.com/?rest_route=/>; rel=\"https://api.w.org/\""]
        let session = mockRootAPIEndpoint(siteAddress: sampleSiteURL, headerFields: headers)
        let useCase = SiteDiscoveryUseCase(session: session)

        // When
        let rootEndpoint = try await useCase.findRootAPIEndpoint(for: sampleSiteURL)

        // Then
        XCTAssertEqual(rootEndpoint, "https://example.com/?rest_route=/")
    }

    func test_findRootAPIEndpoint_returns_default_value_if_no_headers_found() async throws {
        // Given
        let session = mockRootAPIEndpoint(siteAddress: sampleSiteURL, headerFields: [:])
        let useCase = SiteDiscoveryUseCase(session: session)

        // When
        let rootEndpoint = try await useCase.findRootAPIEndpoint(for: sampleSiteURL)

        // Then
        XCTAssertEqual(rootEndpoint, "https://example.com/wp-json/")
    }

}

private extension SiteDiscoveryUseCaseTests {
    func mockRootAPIEndpoint(siteAddress: String,
                             headerFields: [String: String]) -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        let urlSession = URLSession.init(configuration: configuration)
        MockURLProtocol.requestHandler = { request in
            guard let url = request.url, url.absoluteString == siteAddress else {
                throw NetworkError.notFound
            }

            guard let url = URL(string: siteAddress) else {
                throw NetworkError.invalidURL
            }

            guard let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: headerFields) else {
                throw NetworkError.unacceptableStatusCode(statusCode: 500)
            }
            return (response, nil)
        }
        return urlSession
    }
}
