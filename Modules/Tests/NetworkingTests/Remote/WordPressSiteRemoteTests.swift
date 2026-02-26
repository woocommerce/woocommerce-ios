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

    /// Verifies that fetchSiteInfo properly parses the sample response using the discovered wp-json root.
    ///
    func test_fetchSiteInfo_when_discovery_returns_wp_json_root_then_uses_wp_json_url() async throws {
        // Given
        let remote = WordPressSiteRemote(network: network) { _ in "https://test.com/wp-json/" }
        network.simulateResponse(requestUrlSuffix: "test.com/wp-json/", filename: "wordpress-site-info")

        // When
        let site = try await remote.fetchSiteInfo(for: sampleSiteURL)

        // Then
        XCTAssertEqual(site.name, "My WordPress Site")
    }

    /// Verifies that fetchSiteInfo falls back to ?rest_route=/ when discovery returns nil.
    ///
    func test_fetchSiteInfo_when_discovery_fails_then_falls_back_to_rest_route() async throws {
        // Given
        let remote = WordPressSiteRemote(network: network) { _ in nil }
        network.simulateResponse(requestUrlSuffix: "?rest_route=/", filename: "wordpress-site-info")

        // When
        let site = try await remote.fetchSiteInfo(for: sampleSiteURL)

        // Then
        XCTAssertEqual(site.name, "My WordPress Site")
    }

    /// Verifies that fetchSiteInfo properly parses the sample response (default behavior).
    ///
    func test_fetchSiteInfo_properly_returns_site() async throws {
        let remote = WordPressSiteRemote(network: network) { _ in nil }
        network.simulateResponse(requestUrlSuffix: "?rest_route=/", filename: "wordpress-site-info")

        // When
        let site = try await remote.fetchSiteInfo(for: sampleSiteURL)

        // Then
        XCTAssertEqual(site.name, "My WordPress Site")
    }

    /// Verifies that fetchSiteInfo properly relays Networking Layer errors.
    ///
    func test_fetchSiteInfo_properly_relays_networking_errors() async {
        let remote = WordPressSiteRemote(network: network) { _ in nil }
        network.simulateError(requestUrlSuffix: "?rest_route=/", error: NetworkError.notFound())

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
        let remote = WordPressSiteRemote(network: network) { _ in "https://test.com/wp-json/" }
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

    /// Verifies that fetchSitePages uses the ?rest_route= URL style when discovery returns a rest_route root.
    ///
    func test_fetchSitePages_when_discovery_returns_rest_route_root_then_uses_rest_route_url() async throws {
        // Given
        let remote = WordPressSiteRemote(network: network) { _ in "https://test.com/?rest_route=/" }
        network.simulateResponse(requestUrlSuffix: "?rest_route=/wp/v2/pages&_fields=id,title,link", filename: "wp-page-list-success")

        // When
        let list = try await remote.fetchSitePages(for: sampleSiteURL)

        // Then
        XCTAssertEqual(list, [
            .init(id: 21, title: "Cart", link: "https://example.com/cart/"),
            .init(id: 20, title: "Shop", link: "https://example.com/shop/"),
            .init(id: 6, title: "Blog", link: "https://example.com/blog/")
        ])
    }

    /// Verifies that fetchSitePages falls back to ?rest_route= when discovery returns nil.
    ///
    func test_fetchSitePages_when_discovery_fails_then_falls_back_to_rest_route() async throws {
        // Given
        let remote = WordPressSiteRemote(network: network) { _ in nil }
        network.simulateResponse(requestUrlSuffix: "/?rest_route=/wp/v2/pages&_fields=id,title,link", filename: "wp-page-list-success")

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
        let remote = WordPressSiteRemote(network: network) { _ in nil }
        network.simulateResponse(requestUrlSuffix: "/?rest_route=/wp/v2/pages&_fields=id,title,link", filename: "wp-page-list-success")

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
        let remote = WordPressSiteRemote(network: network) { _ in nil }
        network.simulateError(requestUrlSuffix: "/?rest_route=/wp/v2/pages&_fields=id,title,link", error: NetworkError.notFound())

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
