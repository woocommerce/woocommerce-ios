import XCTest
@testable import Networking
@testable import NetworkingCore

final class WordPressAPIDiscoveryTests: XCTestCase {
    let sampleSiteURL = "https://example.com"
    var session: MockURLSession!
    var cache: WordPressRESTAPIRootCache!
    var sut: WordPressAPIDiscovery!

    override func setUp() {
        session = MockURLSession()
        cache = WordPressRESTAPIRootCache()
        sut = WordPressAPIDiscovery(session: session, cache: cache)
    }

    override func tearDown() {
        sut = nil
        cache = nil
        session = nil
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
        XCTAssertEqual(cache.root(for: sampleSiteURL), "https://example.com/wp-json/")
    }

    func test_discoverRESTAPIRootURL_when_discovery_fails_then_does_not_populate_cache() async {
        // Given
        session.simulateResponse(for: sampleSiteURL, headerFields: nil)

        // When
        _ = await sut.discoverRESTAPIRootURL(for: sampleSiteURL)

        // Then
        XCTAssertNil(cache.root(for: sampleSiteURL))
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

    // MARK: - Deduplication Tests

    func test_discoverRESTAPIRootURL_when_concurrent_calls_for_same_url_then_makes_single_request() async {
        // Given
        session.simulateResponse(
            for: sampleSiteURL,
            headerFields: ["Link": "<https://example.com/wp-json/>; rel=\"https://api.w.org/\""]
        )

        // When — two concurrent discoveries for the same URL
        async let result1 = sut.discoverRESTAPIRootURL(for: sampleSiteURL)
        async let result2 = sut.discoverRESTAPIRootURL(for: sampleSiteURL)
        let results = await [result1, result2]

        // Then — both get the same result, but only one HEAD request was made
        XCTAssertEqual(results[0], "https://example.com/wp-json/")
        XCTAssertEqual(results[1], "https://example.com/wp-json/")
        XCTAssertEqual(session.requestCount, 1)
    }

    func test_discoverRESTAPIRootURL_when_concurrent_calls_with_different_casing_then_makes_single_request() async {
        // Given — simulate responses for both URL casings
        session.simulateResponse(
            for: "https://example.com",
            headerFields: ["Link": "<https://example.com/wp-json/>; rel=\"https://api.w.org/\""]
        )
        session.simulateResponse(
            for: "https://Example.COM",
            headerFields: ["Link": "<https://example.com/wp-json/>; rel=\"https://api.w.org/\""]
        )

        // When — two concurrent discoveries with different casing
        async let result1 = sut.discoverRESTAPIRootURL(for: "https://example.com")
        async let result2 = sut.discoverRESTAPIRootURL(for: "https://Example.COM")
        let results = await [result1, result2]

        // Then — both succeed and only one request was made
        XCTAssertEqual(results[0], "https://example.com/wp-json/")
        XCTAssertEqual(results[1], "https://example.com/wp-json/")
        XCTAssertEqual(session.requestCount, 1)
    }

    func test_discoverRESTAPIRootURL_when_previous_request_completed_then_allows_new_request() async {
        // Given
        session.simulateResponse(
            for: sampleSiteURL,
            headerFields: ["Link": "<https://example.com/wp-json/>; rel=\"https://api.w.org/\""]
        )

        // When — sequential discoveries (first completes before second starts)
        _ = await sut.discoverRESTAPIRootURL(for: sampleSiteURL)
        cache.reset()
        _ = await sut.discoverRESTAPIRootURL(for: sampleSiteURL)

        // Then — two separate requests were made
        XCTAssertEqual(session.requestCount, 2)
    }
}
