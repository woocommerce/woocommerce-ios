import XCTest
@testable import Networking
@testable import NetworkingCore

final class WordPressAPIDiscoveryTests: XCTestCase {
    let sampleSiteURL = "https://example.com"
    var session: MockURLSession!
    var sut: WordPressAPIDiscovery!

    override func setUp() {
        session = MockURLSession()
        sut = WordPressAPIDiscovery(session: session)
    }

    override func tearDown() {
        sut = nil
        session = nil
        WordPressRESTAPIRootCache.shared.reset()
        super.tearDown()
    }

    // MARK: - discoverRESTAPIRootURL

    func test_discoverRESTAPIRootURL_when_link_header_contains_wp_json_root_then_returns_wp_json_url() async {
        // Given
        session.simulateResponse(
            for: sampleSiteURL,
            headerFields: ["Link": "<https://example.com/wp-json/>; rel=\"https://api.w.org/\""]
        )

        // When
        let result = await sut.discoverRESTAPIRootURL(for: sampleSiteURL)

        // Then
        XCTAssertEqual(result, "https://example.com/wp-json/")
    }

    func test_discoverRESTAPIRootURL_when_link_header_contains_rest_route_then_returns_rest_route_url() async {
        // Given
        session.simulateResponse(
            for: sampleSiteURL,
            headerFields: ["Link": "<https://example.com/?rest_route=/>; rel=\"https://api.w.org/\""]
        )

        // When
        let result = await sut.discoverRESTAPIRootURL(for: sampleSiteURL)

        // Then
        XCTAssertEqual(result, "https://example.com/?rest_route=/")
    }

    func test_discoverRESTAPIRootURL_when_link_header_contains_multiple_relations_then_returns_api_root() async {
        // Given
        let linkHeader = "<https://example.com/>; rel=\"canonical\", <https://example.com/wp-json/>; rel=\"https://api.w.org/\""
        session.simulateResponse(
            for: sampleSiteURL,
            headerFields: ["Link": linkHeader]
        )

        // When
        let result = await sut.discoverRESTAPIRootURL(for: sampleSiteURL)

        // Then
        XCTAssertEqual(result, "https://example.com/wp-json/")
    }

    func test_discoverRESTAPIRootURL_when_no_link_header_then_returns_nil() async {
        // Given
        session.simulateResponse(for: sampleSiteURL, headerFields: nil)

        // When
        let result = await sut.discoverRESTAPIRootURL(for: sampleSiteURL)

        // Then
        XCTAssertNil(result)
    }

    func test_discoverRESTAPIRootURL_when_link_header_has_no_api_relation_then_returns_nil() async {
        // Given
        session.simulateResponse(
            for: sampleSiteURL,
            headerFields: ["Link": "<https://example.com/>; rel=\"canonical\""]
        )

        // When
        let result = await sut.discoverRESTAPIRootURL(for: sampleSiteURL)

        // Then
        XCTAssertNil(result)
    }

    func test_discoverRESTAPIRootURL_when_network_error_then_returns_nil() async {
        // Given
        session.simulateError(for: sampleSiteURL, error: URLError(.notConnectedToInternet))

        // When
        let result = await sut.discoverRESTAPIRootURL(for: sampleSiteURL)

        // Then
        XCTAssertNil(result)
    }

    func test_discoverRESTAPIRootURL_when_site_url_is_invalid_then_returns_nil() async {
        // Given / When
        let result = await sut.discoverRESTAPIRootURL(for: "not a valid url")

        // Then
        XCTAssertNil(result)
    }

    // MARK: - Cache Population Tests

    func test_discoverRESTAPIRootURL_when_discovery_succeeds_then_populates_cache() async {
        // Given
        session.simulateResponse(
            for: sampleSiteURL,
            headerFields: ["Link": "<https://example.com/wp-json/>; rel=\"https://api.w.org/\""]
        )

        // When
        _ = await sut.discoverRESTAPIRootURL(for: sampleSiteURL)

        // Then
        XCTAssertEqual(WordPressRESTAPIRootCache.shared.root(for: sampleSiteURL), "https://example.com/wp-json/")
    }

    func test_discoverRESTAPIRootURL_when_discovery_fails_then_does_not_populate_cache() async {
        // Given
        session.simulateResponse(for: sampleSiteURL, headerFields: nil)

        // When
        _ = await sut.discoverRESTAPIRootURL(for: sampleSiteURL)

        // Then
        XCTAssertNil(WordPressRESTAPIRootCache.shared.root(for: sampleSiteURL))
    }

    func test_discoverRESTAPIRootURL_sends_head_request() async {
        // Given
        session.simulateResponse(
            for: sampleSiteURL,
            headerFields: ["Link": "<https://example.com/wp-json/>; rel=\"https://api.w.org/\""]
        )

        // When
        _ = await sut.discoverRESTAPIRootURL(for: sampleSiteURL)

        // Then
        XCTAssertEqual(session.lastRequest?.httpMethod, "HEAD")
    }
}
