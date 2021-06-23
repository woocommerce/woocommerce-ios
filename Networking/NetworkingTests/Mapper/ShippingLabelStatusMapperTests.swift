import XCTest
@testable import Networking

/// Unit Tests for `ShippingLabelStatusMapper`
///
class ShippingLabelStatusMapperTests: XCTestCase {

    /// Sample Site ID
    private let sampleSiteID: Int64 = 1234

    /// Sample Order ID
    private let sampleOrderID: Int64 = 1234

    /// Verifies that the Shipping Label Purchase is parsed correctly.
    ///
    func test_ShippingLabelPurchase_is_properly_parsed() {
        guard let shippingLabelList = mapLoadShippingLabelStatus(),
              let shippingLabel = shippingLabelList.first else {
            XCTFail()
            return
        }

        XCTAssertEqual(shippingLabel.siteID, sampleSiteID)
        XCTAssertEqual(shippingLabel.orderID, sampleOrderID)
        XCTAssertEqual(shippingLabel.shippingLabelID, 1825)
        XCTAssertEqual(shippingLabel.carrierID, "usps")
        XCTAssertEqual(shippingLabel.dateCreated, Date(timeIntervalSince1970: 1623764362.682))
        XCTAssertEqual(shippingLabel.packageName, "Small Flat Rate Box")
        XCTAssertEqual(shippingLabel.rate, 7.9)
        XCTAssertEqual(shippingLabel.currency, "USD")
        XCTAssertEqual(shippingLabel.trackingNumber, "9405500205309072644962")
        XCTAssertEqual(shippingLabel.serviceName, "USPS - Priority Mail")
        XCTAssertEqual(shippingLabel.refundableAmount, 7.9)
        XCTAssertEqual(shippingLabel.status, ShippingLabelStatus.purchased)
        XCTAssertNil(shippingLabel.refund)
        XCTAssertEqual(shippingLabel.originAddress, ShippingLabelAddress.fake())
        XCTAssertEqual(shippingLabel.destinationAddress, ShippingLabelAddress.fake())
        XCTAssertEqual(shippingLabel.productIDs, [89])
        XCTAssertEqual(shippingLabel.productNames, ["WordPress Pennant"])
    }
}

/// Private Helpers
///
private extension ShippingLabelStatusMapperTests {

    /// Returns the ShippingLabelStatusMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapShippingLabelStatus(from filename: String) -> [ShippingLabel]? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! ShippingLabelStatusMapper(siteID: sampleSiteID, orderID: sampleOrderID).map(response: response)
    }

    /// Returns the ShippingLabelStatusMapper output upon receiving `shipping-label-status-success`
    ///
    func mapLoadShippingLabelStatus() -> [ShippingLabel]? {
        return mapShippingLabelStatus(from: "shipping-label-status-success")
    }
}
