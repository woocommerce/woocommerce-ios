import XCTest
@testable import Networking

final class WordPressSiteRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    let sampleSiteURL = "https://example.com"

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }

    /// Verifies that fetchSiteInfo properly parses the sample response.
    ///
    func test_fetchSiteInfo_properly_returns_site() async throws {
        let remote = WordPressSiteRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "wp-json", filename: "wordpress-site-info")

        // When
        let site = try await remote.fetchSiteInfo(for: sampleSiteURL)

        // Then
        XCTAssertEqual(site.name, "My WordPress Site")
    }

    /// Verifies that fetchSiteInfo properly relays Networking Layer errors.
    ///
    func test_fetchSiteInfo_properly_relays_networking_errors() async {
        let remote = WordPressSiteRemote(network: network)
        network.simulateError(requestUrlSuffix: "wp-json", error: NetworkError.notFound)

        // When
        var fetchError: Error?
        do {
            let _ = try await remote.fetchSiteInfo(for: sampleSiteURL)
        } catch {
            fetchError = error
        }

        // Then
        XCTAssertNotNil(fetchError)
        XCTAssertTrue(fetchError is NetworkError)
    }

    func test_findRootAPIEndpoint_returns_correct_link_for_root_endpoint() async throws {
        // Given
        let headers = ["Link": "<https://example.com/?rest_route=/>; rel=\"https://api.w.org/\""]
        let session = mockRootAPIEndpoint(siteAddress: sampleSiteURL, headerFields: headers)
        let remote = WordPressSiteRemote(network: network, session: session)

        // When
        let rootEndpoint = try await remote.findRootAPIEndpoint(for: sampleSiteURL)

        // Then
        XCTAssertEqual(rootEndpoint, "https://example.com/?rest_route=/")
    }

    func test_findRootAPIEndpoint_returns_default_value_if_no_headers_found() async throws {
        // Given
        let session = mockRootAPIEndpoint(siteAddress: sampleSiteURL, headerFields: [:])
        let remote = WordPressSiteRemote(network: network, session: session)

        // When
        let rootEndpoint = try await remote.findRootAPIEndpoint(for: sampleSiteURL)

        // Then
        XCTAssertEqual(rootEndpoint, "https://example.com/wp-json")
    }
}

private extension WordPressSiteRemoteTests {
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
