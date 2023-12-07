import XCTest
@testable import Networking

/// Unit Tests for `ShippingLabelPurchaseMapper`
///
class ShippingLabelPurchaseMapperTests: XCTestCase {

    /// Sample Site ID
    private let sampleSiteID: Int64 = 1234

    /// Sample Order ID
    private let sampleOrderID: Int64 = 1234

    /// Verifies that the Shipping Label Purchase is parsed correctly.
    ///
    func test_ShippingLabelPurchase_is_properly_parsed() async {
        guard let shippingLabelList = await mapLoadShippingLabelPurchase(),
              let shippingLabel = shippingLabelList.first else {
            XCTFail()
            return
        }

        XCTAssertEqual(shippingLabel.siteID, sampleSiteID)
        XCTAssertEqual(shippingLabel.orderID, sampleOrderID)
        XCTAssertEqual(shippingLabel.shippingLabelID, 733)
        XCTAssertNil(shippingLabel.carrierID)
        XCTAssertEqual(shippingLabel.dateCreated, Date(timeIntervalSince1970: 1584549793.938))
        XCTAssertEqual(shippingLabel.packageName, "Test")
        XCTAssertNil(shippingLabel.trackingNumber)
        XCTAssertEqual(shippingLabel.serviceName, "USPS - First Class Mail")
        XCTAssertEqual(shippingLabel.refundableAmount, 0)
        XCTAssertEqual(shippingLabel.status, ShippingLabelStatus.purchaseInProgress)
        XCTAssertEqual(shippingLabel.productIDs, [])
        XCTAssertEqual(shippingLabel.productNames, ["Beanie"])
    }

    /// Verifies that the Shipping Label Purchase is parsed correctly.
    ///
    func test_ShippingLabelPurchase_is_properly_parsed_when_response_has_no_data_envelope() async {
        guard let shippingLabelList = await mapLoadShippingLabelPurchaseWithoutDataEnvelope(),
              let shippingLabel = shippingLabelList.first else {
            XCTFail()
            return
        }

        XCTAssertEqual(shippingLabel.siteID, sampleSiteID)
        XCTAssertEqual(shippingLabel.orderID, sampleOrderID)
        XCTAssertEqual(shippingLabel.shippingLabelID, 733)
        XCTAssertNil(shippingLabel.carrierID)
        XCTAssertEqual(shippingLabel.dateCreated, Date(timeIntervalSince1970: 1584549793.938))
        XCTAssertEqual(shippingLabel.packageName, "Test")
        XCTAssertNil(shippingLabel.trackingNumber)
        XCTAssertEqual(shippingLabel.serviceName, "USPS - First Class Mail")
        XCTAssertEqual(shippingLabel.refundableAmount, 0)
        XCTAssertEqual(shippingLabel.status, ShippingLabelStatus.purchaseInProgress)
        XCTAssertEqual(shippingLabel.productIDs, [])
        XCTAssertEqual(shippingLabel.productNames, ["Beanie"])
    }
}

/// Private Helpers
///
private extension ShippingLabelPurchaseMapperTests {

    /// Returns the ShippingLabelPurchaseMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapShippingLabelPurchase(from filename: String) async -> [ShippingLabelPurchase]? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! await ShippingLabelPurchaseMapper(siteID: sampleSiteID, orderID: sampleOrderID).map(response: response)
    }

    /// Returns the ShippingLabelPurchaseMapper output upon receiving `shipping-label-purchase-success`
    ///
    func mapLoadShippingLabelPurchase() async -> [ShippingLabelPurchase]? {
        await mapShippingLabelPurchase(from: "shipping-label-purchase-success")
    }

    /// Returns the ShippingLabelPurchaseMapper output upon receiving `shipping-label-purchase-success-without-data`
    ///
    func mapLoadShippingLabelPurchaseWithoutDataEnvelope() async -> [ShippingLabelPurchase]? {
        await mapShippingLabelPurchase(from: "shipping-label-purchase-success-without-data")
    }
}
