import XCTest
@testable import Networking

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

    /// Verifies that fetchSiteInfo properly parses the sample response.
    ///
    func test_fetchSiteInfo_properly_returns_site() async throws {
        let remote = WordPressSiteRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "?rest_route=/", filename: "wordpress-site-info")

        // When
        let site = try await remote.fetchSiteInfo(for: sampleSiteURL)

        // Then
        XCTAssertEqual(site.name, "My WordPress Site")
    }

    /// Verifies that fetchSiteInfo properly relays Networking Layer errors.
    ///
    func test_fetchSiteInfo_properly_relays_networking_errors() async {
        let remote = WordPressSiteRemote(network: network)
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

    /// Verifies that fetchSitePages properly parses the sample response.
    ///
    func test_fetchSitePages_properly_returns_page_list() async throws {
        let remote = WordPressSiteRemote(network: network)
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
        let remote = WordPressSiteRemote(network: network)
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
