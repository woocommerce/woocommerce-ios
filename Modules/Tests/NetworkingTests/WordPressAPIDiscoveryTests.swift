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

    // MARK: - resolveRESTAPIRootURL

    func test_resolveRESTAPIRootURL_when_root_is_cached_then_returns_it_without_requesting() async {
        // Given
        cache.setRoot("https://example.com/custom-json/", for: sampleSiteURL)

        // When
        let result = await sut.resolveRESTAPIRootURL(for: sampleSiteURL)

        // Then
        XCTAssertEqual(result, "https://example.com/custom-json/")
        XCTAssertEqual(session.requestCount, 0)
    }

    func test_resolveRESTAPIRootURL_when_head_discovery_succeeds_then_validates_and_caches_discovered_root() async {
        // Given
        session.simulateResponse(
            for: sampleSiteURL,
            headerFields: ["Link": "<https://example.com/wp-json/>; rel=\"https://api.w.org/\""]
        )
        session.simulateResponse(
            for: "https://example.com/wp-json/?_fields=namespaces",
            data: restAPIIndexData()
        )

        // When
        let result = await sut.resolveRESTAPIRootURL(for: sampleSiteURL)

        // Then
        XCTAssertEqual(result, "https://example.com/wp-json/")
        XCTAssertEqual(cache.root(for: sampleSiteURL), "https://example.com/wp-json/")
        XCTAssertEqual(session.requestCount, 2)
    }

    func test_resolveRESTAPIRootURL_when_discovered_wp_json_is_unavailable_then_uses_valid_query_route() async {
        // Given
        session.simulateResponse(
            for: sampleSiteURL,
            headerFields: ["Link": "<https://example.com/wp-json/>; rel=\"https://api.w.org/\""]
        )
        session.simulateResponse(for: "https://example.com/wp-json/?_fields=namespaces", statusCode: 404)
        session.simulateResponse(
            for: "https://example.com/?rest_route=/&_fields=namespaces",
            data: restAPIIndexData()
        )

        // When
        let result = await sut.resolveRESTAPIRootURL(for: sampleSiteURL)

        // Then
        XCTAssertEqual(result, "https://example.com/?rest_route=/")
        XCTAssertEqual(cache.root(for: sampleSiteURL), "https://example.com/?rest_route=/")
        XCTAssertEqual(session.requestCount, 3)
    }

    func test_resolveRESTAPIRootURL_when_head_discovery_fails_and_wp_json_is_valid_then_caches_wp_json() async {
        // Given
        session.simulateResponse(for: sampleSiteURL, headerFields: nil)
        session.simulateResponse(
            for: "https://example.com/wp-json/?_fields=namespaces",
            data: restAPIIndexData()
        )

        // When
        let result = await sut.resolveRESTAPIRootURL(for: sampleSiteURL)

        // Then
        XCTAssertEqual(result, "https://example.com/wp-json/")
        XCTAssertEqual(cache.root(for: sampleSiteURL), "https://example.com/wp-json/")
        XCTAssertEqual(session.requestCount, 2)
    }

    func test_resolveRESTAPIRootURL_when_head_request_errors_and_wp_json_is_valid_then_caches_wp_json() async {
        // Given
        session.simulateError(for: sampleSiteURL, error: URLError(.timedOut))
        session.simulateResponse(
            for: "https://example.com/wp-json/?_fields=namespaces",
            data: restAPIIndexData()
        )

        // When
        let result = await sut.resolveRESTAPIRootURL(for: sampleSiteURL)

        // Then
        XCTAssertEqual(result, "https://example.com/wp-json/")
        XCTAssertEqual(cache.root(for: sampleSiteURL), "https://example.com/wp-json/")
        XCTAssertEqual(session.requestCount, 2)
    }

    func test_resolveRESTAPIRootURL_when_wp_json_is_unavailable_and_query_route_is_valid_then_caches_query_route() async {
        // Given
        session.simulateResponse(for: sampleSiteURL, headerFields: nil)
        session.simulateResponse(for: "https://example.com/wp-json/?_fields=namespaces", statusCode: 404)
        session.simulateResponse(
            for: "https://example.com/?rest_route=/&_fields=namespaces",
            data: restAPIIndexData()
        )

        // When
        let result = await sut.resolveRESTAPIRootURL(for: sampleSiteURL)

        // Then
        XCTAssertEqual(result, "https://example.com/?rest_route=/")
        XCTAssertEqual(cache.root(for: sampleSiteURL), "https://example.com/?rest_route=/")
        XCTAssertEqual(session.requestCount, 3)
    }

    func test_resolveRESTAPIRootURL_when_wp_json_returns_non_api_response_then_uses_valid_query_route() async {
        // Given
        session.simulateResponse(for: sampleSiteURL, headerFields: nil)
        session.simulateResponse(
            for: "https://example.com/wp-json/?_fields=namespaces",
            data: Data("<html></html>".utf8)
        )
        session.simulateResponse(
            for: "https://example.com/?rest_route=/&_fields=namespaces",
            data: restAPIIndexData()
        )

        // When
        let result = await sut.resolveRESTAPIRootURL(for: sampleSiteURL)

        // Then
        XCTAssertEqual(result, "https://example.com/?rest_route=/")
        XCTAssertEqual(session.requestCount, 3)
    }

    func test_resolveRESTAPIRootURL_when_neither_fallback_is_a_rest_api_index_then_returns_nil() async {
        // Given
        session.simulateResponse(for: sampleSiteURL, headerFields: nil)
        session.simulateResponse(for: "https://example.com/wp-json/?_fields=namespaces", statusCode: 404)
        session.simulateResponse(for: "https://example.com/?rest_route=/&_fields=namespaces", statusCode: 403)

        // When
        let result = await sut.resolveRESTAPIRootURL(for: sampleSiteURL)

        // Then
        XCTAssertNil(result)
        XCTAssertNil(cache.root(for: sampleSiteURL))
        XCTAssertEqual(session.requestCount, 3)
    }

    func test_resolveRESTAPIRootURL_when_called_concurrently_then_shares_the_resolution_requests() async {
        // Given
        session.simulateResponse(for: sampleSiteURL, headerFields: nil)
        session.simulateResponse(
            for: "https://example.com/wp-json/?_fields=namespaces",
            data: restAPIIndexData()
        )

        // When
        async let firstResult = sut.resolveRESTAPIRootURL(for: sampleSiteURL)
        async let secondResult = sut.resolveRESTAPIRootURL(for: sampleSiteURL)
        let results = await [firstResult, secondResult]

        // Then
        XCTAssertEqual(results, ["https://example.com/wp-json/", "https://example.com/wp-json/"])
        XCTAssertEqual(session.requestCount, 2)
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

private extension WordPressAPIDiscoveryTests {
    func restAPIIndexData() -> Data {
        Data(#"{"namespaces":["wp/v2","wc/v3"]}"#.utf8)
    }
}
