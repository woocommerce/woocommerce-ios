import XCTest
@testable import Networking

/// Unit Tests for `ShippingLabelStatusMapper`
///
class ShippingLabelStatusMapperTests: XCTestCase {

    /// Sample Site ID
    private let sampleSiteID: Int64 = 1234

    /// Sample Order ID
    private let sampleOrderID: Int64 = 1234

    /// Verifies that the Shipping Label Status Polling Response is parsed correctly when it receives a purchased shipping label.
    ///
    func test_ShippingLabelStatusPollingResponse_is_properly_parsed_for_purchased_label() {
        // Given
        guard let shippingLabelList = mapLoadShippingLabelStatus(),
              let shippingLabelResponse = shippingLabelList.first else {
            XCTFail()
            return
        }

        // Assert
        XCTAssertEqual(shippingLabelResponse.status, .purchased)

        // Then
        let shippingLabel = shippingLabelResponse.getPurchasedLabel()

        // Assert
        XCTAssertEqual(shippingLabel?.siteID, sampleSiteID)
        XCTAssertEqual(shippingLabel?.orderID, sampleOrderID)
        XCTAssertEqual(shippingLabel?.shippingLabelID, 1825)
        XCTAssertEqual(shippingLabel?.carrierID, "usps")
        XCTAssertEqual(shippingLabel?.dateCreated, Date(timeIntervalSince1970: 1623764362.682))
        XCTAssertEqual(shippingLabel?.packageName, "Small Flat Rate Box")
        XCTAssertEqual(shippingLabel?.rate, 7.9)
        XCTAssertEqual(shippingLabel?.currency, "USD")
        XCTAssertEqual(shippingLabel?.trackingNumber, "9405500205309072644962")
        XCTAssertEqual(shippingLabel?.serviceName, "USPS - Priority Mail")
        XCTAssertEqual(shippingLabel?.refundableAmount, 7.9)
        XCTAssertEqual(shippingLabel?.status, ShippingLabelStatus.purchased)
        XCTAssertNil(shippingLabel?.refund)
        XCTAssertEqual(shippingLabel?.originAddress, ShippingLabelAddress.fake())
        XCTAssertEqual(shippingLabel?.destinationAddress, ShippingLabelAddress.fake())
        XCTAssertEqual(shippingLabel?.productIDs, [89])
        XCTAssertEqual(shippingLabel?.productNames, ["WordPress Pennant"])
    }

    /// Verifies that the Shipping Label Status Polling Response is parsed correctly when it receives a pending shipping label purchase.
    ///
    func test_ShippingLabelStatusPollingResponse_is_properly_parsed_for_pending_label_purchase() {
        guard let shippingLabelList = mapLoadShippingLabelPurchaseStatus(),
              let shippingLabelResponse = shippingLabelList.first else {
            XCTFail()
            return
        }

        // Assert
        XCTAssertEqual(shippingLabelResponse.status, .purchaseInProgress)
    }
}

/// Private Helpers
///
private extension ShippingLabelStatusMapperTests {

    /// Returns the ShippingLabelStatusMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapShippingLabelStatus(from filename: String) -> [ShippingLabelStatusPollingResponse]? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! ShippingLabelStatusMapper(siteID: sampleSiteID, orderID: sampleOrderID).map(response: response)
    }

    /// Returns the ShippingLabelStatusMapper output upon receiving `shipping-label-status-success`
    ///
    func mapLoadShippingLabelStatus() -> [ShippingLabelStatusPollingResponse]? {
        return mapShippingLabelStatus(from: "shipping-label-status-success")
    }

    /// Returns the ShippingLabelStatusMapper output upon receiving `shipping-label-purchase-success`
    ///
    func mapLoadShippingLabelPurchaseStatus() -> [ShippingLabelStatusPollingResponse]? {
        return mapShippingLabelStatus(from: "shipping-label-purchase-success")
    }
}
