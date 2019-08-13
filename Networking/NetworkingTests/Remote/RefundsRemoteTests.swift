import XCTest
@testable import Networking

/// RefundsRemoteTests:
///
final class RefundsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockupNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID = 1234

    /// Dummy Order ID
    ///
    let sampleOrderID = 1467

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }

    // MARK: - Load All Order Refunds Tests

    /// Verifies that loadOrderRefunds properly parses the `order-refunds-list` sample response.
    ///
    func testLoadAllOrderRefundsProperlyReturnsParsedModels() {
        let remote = RefundsRemote(network: network)
        let expectation = self.expectation(description: "Load All Order Refunds")

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/refunds", filename: "order-refunds-list")

        remote.loadOrderRefunds(for: sampleSiteID, by: sampleOrderID) { refunds, error in
            XCTAssertNil(error)
            XCTAssertNotNil(refunds)
            XCTAssert(refunds?.count == 2)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that loadOrderRefunds properly relays Networking Layer errors.
    ///
    func testLoadAllOrderRefundsProperlyRelaysNetwokingErrors() {
        let remote = RefundsRemote(network: network)
        let expectation = self.expectation(description: "Load All Order Refunds")

        remote.loadOrderRefunds(for: sampleSiteID, by: sampleOrderID) { refunds, error in
            XCTAssertNil(refunds)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

}
