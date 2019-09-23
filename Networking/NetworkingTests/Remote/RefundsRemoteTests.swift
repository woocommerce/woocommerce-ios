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

        remote.loadAllRefunds(for: sampleSiteID, by: sampleOrderID) { refunds, error in
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

        remote.loadAllRefunds(for: sampleSiteID, by: sampleOrderID) { refunds, error in
            XCTAssertNil(refunds)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    ///Verifies that createRefund properly parses the `create-order-refund-response` sample response.
    ///
    func testPartialRefundForSingleProductIncludingTax() {
        let remote = RefundsRemote(network: network)
        let expectation = self.expectation(description: "Full refund for single product including tax")

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/refunds", filename: "create-order-refund-response")

        let itemRefund = OrderItemRefund(itemID: "123", quantity: 1, refundTotal: "8.00", refundTax: [TaxRefund(taxIDLineItem: "789", amount: "2.00")])
        let refund = Refund(amount: "10.00", reason: "Product No Longer Needed", items: [itemRefund])
        remote.createRefund(for: sampleSiteID, by: sampleOrderID, refund: refund) { (orderRefund, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(orderRefund)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    ///Verifies that createRefund properly parses the `create-manual-order-refund-response` sample response.
    ///
    func testManualRefundForSingleProductIncludingTax() {
        let remote = RefundsRemote(network: network)
        let expectation = self.expectation(description: "Partial refund for single product including tax")

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/refunds", filename: "create-manual-order-refund-response")

        let itemRefund = OrderItemRefund(itemID: "123", quantity: 1, refundTotal: "8.00", refundTax: [TaxRefund(taxIDLineItem: "789", amount: "2.00")])
        let refund = Refund(amount: "10.00", reason: "Product No Longer Needed", apiRefund: false, items: [itemRefund])
        remote.createRefund(for: sampleSiteID, by: sampleOrderID, refund: refund) { (orderRefund, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(orderRefund)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that createRefund properly relays Networking Layer errors.
    ///
    func testPartialRefundForSingleProductIncludingTaxRelaysNetwokingErrors() {
        let remote = RefundsRemote(network: network)
        let expectation = self.expectation(description: "Partial refund for single product including tax")

        let itemRefund = OrderItemRefund(itemID: "123", quantity: 1, refundTotal: "8.00", refundTax: [TaxRefund(taxIDLineItem: "789", amount: "2.00")])
        let refund = Refund(amount: "10.00", reason: "Product No Longer Needed", items: [itemRefund])
        remote.createRefund(for: sampleSiteID, by: sampleOrderID, refund: refund) { (orderRefund, error) in
            XCTAssertNil(orderRefund)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
