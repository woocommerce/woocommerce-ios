import XCTest
@testable import Networking
import TestKit

/// ProductsReportsRemote Unit Tests
///
class ProductsReportsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Repeat always!
    ///
    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    // MARK: - loadTopProductsReport

    /// Verifies that `loadTopProductsReport` properly parses the successful response
    ///
    func test_loadTopProductsReport_returns_success() async throws {
        // Given
        let remote = ProductsReportsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "reports/products", filename: "reports-products")

        // When
        let products = try await remote.loadTopProductsReport(for: self.sampleSiteID,
                                                              timeZone: .current,
                                                              earliestDateToInclude: Date(),
                                                              latestDateToInclude: Date(),
                                                              quantity: 2)

        //Then
        XCTAssertEqual(products.count, 2)
    }

    /// Verifies that `loadTopProductsReport` correctly returns a Dotcom Error, whenever the request failed.
    ///
    func test_loadTopProductsReport_properly_parses_error_responses() async throws {
        // Given
        let remote = ProductsReportsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "reports/products", filename: "generic_error")

        // When & Then
        await assertThrowsError({
            _ = try await remote.loadTopProductsReport(for: self.sampleSiteID,
                                                       timeZone: .current,
                                                       earliestDateToInclude: Date(),
                                                       latestDateToInclude: Date(),
                                                       quantity: 5)
        }, errorAssert: { ($0 as? DotcomError) == .unauthorized })
    }
}
