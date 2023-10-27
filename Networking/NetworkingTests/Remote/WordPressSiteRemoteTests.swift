import XCTest
@testable import Networking

final class WordPressSiteRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    let sampleSiteURL = "https://example.com"

    let siteDiscoveryUseCase = MockSiteDiscoveryUseCase()

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
        let rootEndpoint = sampleSiteURL + "/" + "wp-json/"
        siteDiscoveryUseCase.mockRootAPIEndpoint(with: rootEndpoint)
    }

    /// Verifies that fetchSiteInfo properly parses the sample response.
    ///
    func test_fetchSiteInfo_properly_returns_site() async throws {
        // Given
        let remote = WordPressSiteRemote(network: network,
                                         siteDiscoveryUseCase: siteDiscoveryUseCase)
        network.simulateResponse(requestUrlSuffix: "wp-json/", filename: "wordpress-site-info")

        // When
        let site = try await remote.fetchSiteInfo(for: sampleSiteURL)

        // Then
        XCTAssertEqual(site.name, "My WordPress Site")
    }

    /// Verifies that fetchSiteInfo properly relays Networking Layer errors.
    ///
    func test_fetchSiteInfo_properly_relays_networking_errors() async {
        // Given
        let remote = WordPressSiteRemote(network: network,
                                         siteDiscoveryUseCase: siteDiscoveryUseCase)
        network.simulateError(requestUrlSuffix: "wp-json/", error: NetworkError.notFound)

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
}
