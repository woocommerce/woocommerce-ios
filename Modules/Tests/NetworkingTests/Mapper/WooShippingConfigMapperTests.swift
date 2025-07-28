import XCTest
@testable import Networking
@testable import NetworkingCore

/// Unit Tests for `WooShippingConfigMapper`
///
final class WooShippingConfigMapperTests: XCTestCase {
    private let sampleSiteID: Int64 = 1234
    private let sampleOrderID: Int64 = 1234

    func test_config_info_is_properly_parsed() throws {
        guard let config = mapLoadShippingLabelConfig() else {
            XCTFail()
            return
        }

        XCTAssertEqual(config.shipments.count, 3)
        let shipment0 = try XCTUnwrap(config.shipments.first(where: { $0.index == "0" }))
        XCTAssertNil(shipment0.shippingLabel) // non-purchased status means no label found
        XCTAssertEqual(shipment0.items.count, 1)

        let shipment1 = try XCTUnwrap(config.shipments.first(where: { $0.index == "1" }))
        XCTAssertEqual(shipment1.shippingLabel?.shippingLabelID, 4871)
        XCTAssertEqual(shipment1.items.count, 1)

        let shipment2 = try XCTUnwrap(config.shipments.first(where: { $0.index == "2" }))
        XCTAssertEqual(shipment2.shippingLabel?.shippingLabelID, 4873)
        XCTAssertNotNil(shipment2.shippingLabel?.refund)
        XCTAssertEqual(shipment2.items.count, 1)

        let shippingLabelData = try XCTUnwrap(config.shippingLabelData?.currentOrderLabels)
        XCTAssertEqual(shippingLabelData.count, 3)
        XCTAssertEqual(shippingLabelData.first?.shipmentID, "1")
        XCTAssertEqual(shippingLabelData.first?.shippingLabelID, 4871)
    }

    func test_config_info_is_properly_parsed_when_response_has_no_data_envelope() throws {
        guard let config = mapLoadShippingLabelConfig() else {
            XCTFail()
            return
        }

        XCTAssertEqual(config.shipments.count, 3)
        let shipment0 = try XCTUnwrap(config.shipments.first(where: { $0.index == "0" }))
        XCTAssertNil(shipment0.shippingLabel) // non-purchased status means no label found
        XCTAssertEqual(shipment0.items.count, 1)

        let shipment1 = try XCTUnwrap(config.shipments.first(where: { $0.index == "1" }))
        XCTAssertEqual(shipment1.shippingLabel?.shippingLabelID, 4871)
        XCTAssertNil(shipment1.shippingLabel?.refund)
        XCTAssertEqual(shipment1.items.count, 1)

        let shipment2 = try XCTUnwrap(config.shipments.first(where: { $0.index == "2" }))
        XCTAssertEqual(shipment2.shippingLabel?.shippingLabelID, 4873)
        XCTAssertNotNil(shipment2.shippingLabel?.refund)
        XCTAssertEqual(shipment2.items.count, 1)

        let shippingLabelData = try XCTUnwrap(config.shippingLabelData?.currentOrderLabels)
        XCTAssertEqual(shippingLabelData.count, 3)
        XCTAssertEqual(shippingLabelData.first?.shipmentID, "1")
        XCTAssertEqual(shippingLabelData.first?.shippingLabelID, 4871)
    }
}

/// Private Helpers
///
private extension WooShippingConfigMapperTests {

    /// Returns the `WooShippingConfigMapper` output upon receiving `filename` (Data Encoded)
    ///
    func mapShippingLabelConfig(from filename: String) -> WooShippingConfig? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! WooShippingConfigMapper(siteID: sampleSiteID,
                                            orderID: sampleOrderID).map(response: response)
    }

    /// Returns the `WooShippingConfigMapper` output upon receiving `shipping-label-config-success`
    ///
    func mapLoadShippingLabelConfig() -> WooShippingConfig? {
        mapShippingLabelConfig(from: "shipping-label-config-success")
    }

    /// Returns the `WooShippingConfigMapper` output upon receiving `shipping-label-config-success-without-data`
    ///
    func mapLoadShippingLabelConfigWithoutDataEnvelope() -> WooShippingConfig? {
        mapShippingLabelConfig(from: "shipping-label-config-success-without-data")
    }
}
