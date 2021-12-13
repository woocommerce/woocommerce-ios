import XCTest
@testable import Networking


/// ReportRemote Unit Tests
///
class ReportRemoteTests: XCTestCase {

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

    // MARK: - loadOrdersTotals

    /// Verifies that `loadOrdersTotals` properly parses the successful response
    ///
    func test_loadOrdersTotals_returns_success() throws {
        // Given
        let remote = ReportRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "reports/orders/totals", filename: "report-orders")

        // When
        let result: Result<[OrderStatus], Error> = waitFor { promise in
            remote.loadOrdersTotals(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        //Then
        XCTAssertTrue(result.isSuccess)
        let reportTotals = try XCTUnwrap(result.get())
        XCTAssertEqual(reportTotals.count, 9)
    }

    /// Verifies that `loadOrdersTotals` correctly returns a Dotcom Error, whenever the request failed.
    ///
    func test_loadOrdersTotals_properly_parses_error_responses() {
        // Given
        let remote = ReportRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "reports/orders/totals", filename: "generic_error")

        // When
        let result: Result<[OrderStatus], Error> = waitFor { promise in
            remote.loadOrdersTotals(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        //Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? DotcomError, .unauthorized)
    }
}
