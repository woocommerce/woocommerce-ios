import XCTest
@testable import Networking


/// OrderStatusRemote Unit Tests
///
class OrderStatusRemoteTests: XCTestCase {

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

    /// Verifies that loadOrderStatuses properly parses the sample response.
    ///
    func testLoadOrderStatusesProperlyReturnsParsedStatuses() {
        let remote = OrderStatusRemote(network: network)
        let expectation = self.expectation(description: "Load order statuses")

        network.simulateResponse(requestUrlSuffix: "reports/orders/totals", filename: "order-statuses")
        remote.loadOrderStatuses(for: sampleSiteID, completion: { (orderStatuses, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(orderStatuses)
            XCTAssertEqual(orderStatuses?.count, 8)
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadGeneralSettings properly relays Networking Layer errors.
    ///
    func testLoadOrderStatusesProperlyRelaysNetwokingErrors() {
        let remote = OrderStatusRemote(network: network)
        let expectation = self.expectation(description: "Load order status contains errors")

        remote.loadOrderStatuses(for: sampleSiteID) { (orderStatuses, error) in
            XCTAssertNil(orderStatuses)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
