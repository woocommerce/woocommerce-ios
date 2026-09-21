import XCTest
@testable import Networking
@testable import NetworkingCore

final class WordPressSiteRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    let sampleSiteURL = "https://test.com"

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }

    // MARK: - fetchSiteInfo

    /// Verifies that fetchSiteInfo properly parses the sample response using the cached wp-json root.
    ///
    func test_fetchSiteInfo_when_cache_contains_wp_json_root_then_uses_wp_json_url() async throws {
        // Given
        let remote = makeRemote(cachedRoot: "https://test.com/wp-json/")
        network.simulateResponse(requestUrlSuffix: "test.com/wp-json/", filename: "wordpress-site-info")

        // When
        let site = try await remote.fetchSiteInfo(for: sampleSiteURL)

        // Then
        XCTAssertEqual(site.name, "My WordPress Site")
    }

    /// Verifies that fetchSiteInfo uses the root returned by discovery.
    ///
    func test_fetchSiteInfo_when_discovery_returns_custom_root_then_uses_discovered_url() async throws {
        // Given
        let remote = makeRemote(cachedRoot: nil) { _ in "https://test.com/custom-json/" }
        network.simulateResponse(requestUrlSuffix: "custom-json/", filename: "wordpress-site-info")

        // When
        let site = try await remote.fetchSiteInfo(for: sampleSiteURL)

        // Then
        XCTAssertEqual(site.name, "My WordPress Site")
    }

    /// Verifies that fetchSiteInfo falls back to /wp-json/ when discovery returns nil.
    ///
    func test_fetchSiteInfo_when_discovery_fails_then_falls_back_to_wp_json() async throws {
        // Given
        let remote = makeRemote(cachedRoot: nil)
        network.simulateResponse(requestUrlSuffix: "wp-json/", filename: "wordpress-site-info")

        // When
        let site = try await remote.fetchSiteInfo(for: sampleSiteURL)

        // Then
        XCTAssertEqual(site.name, "My WordPress Site")
    }

    func test_fetchSiteInfo_when_cached_root_fails_then_retries_with_newly_discovered_root() async throws {
        // Given
        let cache = MockRESTAPIRootCache(stubbedRoot: "https://test.com/?rest_route=/")
        let replacementRoot = "https://test.com/wp-json/"
        let remote = makeRemote(cache: cache) { _ in
            cache.stubbedRoot = replacementRoot
            return replacementRoot
        }
        network.simulateError(
            requestUrlSuffix: "?rest_route=/",
            error: NetworkError.unacceptableStatusCode(statusCode: 403)
        )
        network.simulateResponse(requestUrlSuffix: "wp-json/", filename: "wordpress-site-info")

        // When
        let site = try await remote.fetchSiteInfo(for: sampleSiteURL)

        // Then
        XCTAssertEqual(site.name, "My WordPress Site")
        XCTAssertEqual(cache.root(for: sampleSiteURL), replacementRoot)
        XCTAssertEqual(network.requestsForResponseData.count, 2)
    }

    /// Verifies that fetchSiteInfo properly parses the sample response (default behavior).
    ///
    func test_fetchSiteInfo_properly_returns_site() async throws {
        let remote = makeRemote(cachedRoot: nil)
        network.simulateResponse(requestUrlSuffix: "wp-json/", filename: "wordpress-site-info")

        // When
        let site = try await remote.fetchSiteInfo(for: sampleSiteURL)

        // Then
        XCTAssertEqual(site.name, "My WordPress Site")
    }

    /// Verifies that fetchSiteInfo properly relays Networking Layer errors.
    ///
    func test_fetchSiteInfo_properly_relays_networking_errors() async {
        let remote = makeRemote(cachedRoot: nil)
        network.simulateError(requestUrlSuffix: "wp-json/", error: NetworkError.notFound())

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

    // MARK: - fetchSitePages

    /// Verifies that fetchSitePages uses the wp-json URL style when discovery returns a wp-json root.
    ///
    func test_fetchSitePages_when_discovery_returns_wp_json_root_then_uses_wp_json_url() async throws {
        // Given
        let remote = makeRemote(cachedRoot: "https://test.com/wp-json/")
        network.simulateResponse(requestUrlSuffix: "wp-json/wp/v2/pages?_fields=id,title,link", filename: "wp-page-list-success")

        // When
        let list = try await remote.fetchSitePages(for: sampleSiteURL)

        // Then
        XCTAssertEqual(list, [
            .init(id: 21, title: "Cart", link: "https://example.com/cart/"),
            .init(id: 20, title: "Shop", link: "https://example.com/shop/"),
            .init(id: 6, title: "Blog", link: "https://example.com/blog/")
        ])
    }

    /// Verifies that fetchSitePages appends the pages path to the discovered ?rest_route= root.
    ///
    func test_fetchSitePages_when_discovery_returns_rest_route_root_then_appends_pages_path() async throws {
        // Given
        let remote = makeRemote(cachedRoot: "https://test.com/?rest_route=/")
        network.simulateResponse(requestUrlSuffix: "?rest_route=/wp/v2/pages?_fields=id,title,link", filename: "wp-page-list-success")

        // When
        let list = try await remote.fetchSitePages(for: sampleSiteURL)

        // Then
        XCTAssertEqual(list, [
            .init(id: 21, title: "Cart", link: "https://example.com/cart/"),
            .init(id: 20, title: "Shop", link: "https://example.com/shop/"),
            .init(id: 6, title: "Blog", link: "https://example.com/blog/")
        ])
    }

    /// Verifies that fetchSitePages falls back to the /wp-json/ path when discovery returns nil.
    ///
    func test_fetchSitePages_when_discovery_fails_then_falls_back_to_wp_json() async throws {
        // Given
        let remote = makeRemote(cachedRoot: nil)
        network.simulateResponse(requestUrlSuffix: "wp-json/wp/v2/pages?_fields=id,title,link", filename: "wp-page-list-success")

        // When
        let list = try await remote.fetchSitePages(for: sampleSiteURL)

        // Then
        XCTAssertEqual(list, [
            .init(id: 21, title: "Cart", link: "https://example.com/cart/"),
            .init(id: 20, title: "Shop", link: "https://example.com/shop/"),
            .init(id: 6, title: "Blog", link: "https://example.com/blog/")
        ])
    }

    /// Verifies that fetchSitePages properly parses the sample response.
    ///
    func test_fetchSitePages_properly_returns_page_list() async throws {
        let remote = makeRemote(cachedRoot: nil)
        network.simulateResponse(requestUrlSuffix: "wp-json/wp/v2/pages?_fields=id,title,link", filename: "wp-page-list-success")

        // When
        let list = try await remote.fetchSitePages(for: sampleSiteURL)

        // Then
        XCTAssertEqual(list, [
            .init(id: 21, title: "Cart", link: "https://example.com/cart/"),
            .init(id: 20, title: "Shop", link: "https://example.com/shop/"),
            .init(id: 6, title: "Blog", link: "https://example.com/blog/")
        ])
    }

    /// Verifies that fetchSitePages properly relays Networking Layer errors.
    ///
    func test_fetchSitePages_properly_relays_networking_errors() async {
        let remote = makeRemote(cachedRoot: nil)
        network.simulateError(requestUrlSuffix: "wp-json/wp/v2/pages?_fields=id,title,link", error: NetworkError.notFound())

        // When
        var fetchError: Error?
        do {
            let _ = try await remote.fetchSitePages(for: sampleSiteURL)
        } catch {
            fetchError = error
        }

        // Then
        XCTAssertNotNil(fetchError)
        XCTAssertTrue(fetchError is NetworkError)
    }
}

private extension WordPressSiteRemoteTests {
    func makeRemote(cachedRoot: String?,
                    discovery: @escaping (String) async -> String? = { _ in nil }) -> WordPressSiteRemote {
        makeRemote(cache: MockRESTAPIRootCache(stubbedRoot: cachedRoot), discovery: discovery)
    }

    func makeRemote(cache: RESTAPIRootCaching,
                    discovery: @escaping (String) async -> String? = { _ in nil }) -> WordPressSiteRemote {
        WordPressSiteRemote(
            network: network,
            apiRootCache: cache,
            discoverRESTAPIRoot: discovery
        )
    }
}
