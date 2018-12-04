import XCTest
@testable import Networking


/// ReportRemote Unit Tests
///
class ReportRemoteTests: XCTestCase {
    /// Dummy Network Wrapper
    ///
    let network = MockupNetwork()
    /// Dummy Site ID
    ///
    let sampleSiteID = 1234
    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }

    /// Verifies that 'loadOrderTotals' properly parses the successful response
    ///
    func testOrderTotalsReturnsSuccess() {
        let expectation = self.expectation(description: "Load order totals")
        let remote = ReportRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "reports/orders/totals", filename: "report-orders")
        remote.loadOrderTotals(for: sampleSiteID) { (reportTotals, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(reportTotals)
            XCTAssertEqual(reportTotals?.count, 8)
            XCTAssertEqual(reportTotals?[.pending], 123)
            XCTAssertEqual(reportTotals?[.processing], 4)
            XCTAssertEqual(reportTotals?[.onHold], 5)
            XCTAssertEqual(reportTotals?[.completed], 6)
            XCTAssertEqual(reportTotals?[.cancelled], 7)
            XCTAssertEqual(reportTotals?[.refunded], 8)
            XCTAssertEqual(reportTotals?[.failed], 9)
            XCTAssertEqual(reportTotals?[OrderStatus(rawValue: "cia-investigation")], 10)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `loadOrderTotals` correctly returns a Dotcom Error, whenever the request failed.
    ///
    func testOrderTotalsProperlyParsesErrorResponses() {
        let expectation = self.expectation(description: "Error Handling")
        let remote = ReportRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "reports/orders/totals", filename: "generic_error")
        remote.loadOrderTotals(for: sampleSiteID) { (reportTotals, error) in
            XCTAssertNil(reportTotals)
            XCTAssertNotNil(error)
            let error = error as? DotcomError
            XCTAssertEqual(error?.code, "unknown_token")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
