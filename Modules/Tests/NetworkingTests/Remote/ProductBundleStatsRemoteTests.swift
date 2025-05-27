import XCTest
import TestKit
@testable import Networking


/// ProductBundleStatsRemote Unit Tests
///
class ProductBundleStatsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }


    /// Verifies that loadProductBundleStats properly parses the `ProductBundleStats` sample response.
    ///
    func test_loadProductBundleStats_properly_returns_parsed_stats() async throws {
        // Given
        let remote = ProductBundleStatsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "reports/bundles/stats", filename: "product-bundle-stats")

        // When
        let productBundleStats = try await remote.loadProductBundleStats(for: self.sampleSiteID,
                                                                         unit: .daily,
                                                                         timeZone: .gmt,
                                                                         earliestDateToInclude: Date(),
                                                                         latestDateToInclude: Date(),
                                                                         quantity: 2,
                                                                         forceRefresh: false)

        // Then
        XCTAssertEqual(productBundleStats.intervals.count, 2)
    }

    /// Verifies that loadProductBundleStats properly relays Networking Layer errors.
    ///
    func test_loadProductBundleStats_properly_relays_networking_errors() async {
        // Given
        let remote = ProductBundleStatsRemote(network: network)
        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 403)
        network.simulateError(requestUrlSuffix: "reports/bundles/stats", error: expectedError)

        // When & Then
        await assertThrowsError({
            _ = try await remote.loadProductBundleStats(for: self.sampleSiteID,
                                                        unit: .daily,
                                                        timeZone: .gmt,
                                                        earliestDateToInclude: Date(),
                                                        latestDateToInclude: Date(),
                                                        quantity: 2,
                                                        forceRefresh: false)
        }, errorAssert: { ($0 as? NetworkError) == expectedError })
    }

    /// Verifies that loadTopProductBundlesReport properly parses the sample response.
    ///
    func test_loadTopProductBundlesReport_properly_returns_parsed_bundles() async throws {
        // Given
        let remote = ProductBundleStatsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "reports/bundles", filename: "product-bundle-top-bundles")

        // When
        let topBundles = try await remote.loadTopProductBundlesReport(for: self.sampleSiteID,
                                                                      timeZone: .gmt,
                                                                      earliestDateToInclude: Date(),
                                                                      latestDateToInclude: Date(),
                                                                      quantity: 5)

        // Then
        XCTAssertEqual(topBundles.count, 5)
    }

    /// Verifies that loadTopProductBundlesReport properly relays Networking Layer errors.
    ///
    func test_loadTopProductBundlesReport_properly_relays_networking_errors() async {
        // Given
        let remote = ProductBundleStatsRemote(network: network)
        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 403)
        network.simulateError(requestUrlSuffix: "reports/bundles", error: expectedError)

        // When & Then
        await assertThrowsError({
            _ = try await remote.loadTopProductBundlesReport(for: self.sampleSiteID,
                                                             timeZone: .gmt,
                                                             earliestDateToInclude: Date(),
                                                             latestDateToInclude: Date(),
                                                             quantity: 5)
        }, errorAssert: { ($0 as? NetworkError) == expectedError })
    }
}
