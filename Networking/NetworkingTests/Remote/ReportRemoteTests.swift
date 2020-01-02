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
    let sampleSiteID: Int64 = 1234

    /// Repeat always!
    ///
    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    // MARK: - loadOrderTotals

    /// Verifies that 'loadOrderTotals' properly parses the successful response
    ///
    func testOrderTotalsReturnsSuccess() {
        let expectation = self.expectation(description: "Load order totals")
        let remote = ReportRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "reports/orders/totals", filename: "report-orders")
        remote.loadOrderTotals(for: sampleSiteID) { (reportTotals, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(reportTotals)
            XCTAssertEqual(reportTotals?.count, 9)
            XCTAssertEqual(reportTotals?[.pending], 123)
            XCTAssertEqual(reportTotals?[.processing], 4)
            XCTAssertEqual(reportTotals?[.onHold], 5)
            XCTAssertEqual(reportTotals?[.completed], 6)
            XCTAssertEqual(reportTotals?[.cancelled], 7)
            XCTAssertEqual(reportTotals?[.refunded], 8)
            XCTAssertEqual(reportTotals?[.failed], 9)
            XCTAssertEqual(reportTotals?[OrderStatusEnum(rawValue: "cia-investigation")], 10)
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
            guard let error = error as? DotcomError else {
                XCTFail()
                return
            }

            XCTAssert(error == .unauthorized)
            XCTAssertEqual(reportTotals?.isEmpty, true)

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - loadOrderStatuses

    /// Verifies that 'loadOrderStatuses' properly parses the successful response
    ///
    func testLoadOrderStatusesReturnsSuccess() {
        let expectation = self.expectation(description: "Load order statuses")
        let remote = ReportRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "reports/orders/totals", filename: "report-orders")
        remote.loadOrderStatuses(for: sampleSiteID) { (orderStatuses, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(orderStatuses)
            XCTAssertEqual(orderStatuses?.count, 9)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `loadOrderStatuses` correctly returns a Dotcom Error, whenever the request failed.
    ///
    func testLoadOrderStatusesProperlyParsesErrorResponses() {
        let expectation = self.expectation(description: "Error Handling")
        let remote = ReportRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "reports/orders/totals", filename: "generic_error")
        remote.loadOrderTotals(for: sampleSiteID) { (reportTotals, error) in
            guard let error = error as? DotcomError else {
                XCTFail()
                return
            }

            XCTAssert(error == .unauthorized)
            XCTAssertEqual(reportTotals?.isEmpty, true)

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
