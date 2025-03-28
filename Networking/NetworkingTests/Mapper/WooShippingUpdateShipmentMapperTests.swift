import XCTest
@testable import Networking

/// Unit Tests for `WooShippingUpdateShipmentMapper`
///
final class WooShippingUpdateShipmentMapperTests: XCTestCase {
    private let sampleSiteID: Int64 = 1234
    private let sampleOrderID: Int64 = 1234

    func test_shipments_are_properly_parsed() throws {
        guard let config = mapLoadShippingLabelConfig() else {
            XCTFail()
            return
        }

        XCTAssertEqual(config.shipments.count, 3)
        let shipment = try XCTUnwrap(config.shipments["0"])

        let shipmentItem = try XCTUnwrap(shipment.first)
        XCTAssertEqual(shipmentItem.id, 209)
        XCTAssertEqual(shipmentItem.subItems, ["209-sub-0", "209-sub-1", "209-sub-2"])
    }

    func test_shipments_are_properly_parsed_when_response_has_no_data_envelope() throws {
        guard let config = mapLoadShippingLabelConfig() else {
            XCTFail()
            return
        }

        XCTAssertEqual(config.shipments.count, 3)
        let shipment = try XCTUnwrap(config.shipments["1"])

        let shipmentItem = try XCTUnwrap(shipment[safe: 2])
        XCTAssertEqual(shipmentItem.id, 212)
        XCTAssertEqual(shipmentItem.subItems, ["212-sub-0", "212-sub-1", "212-sub-2"])
    }
}
/// Private Helpers
///
private extension WooShippingUpdateShipmentMapperTests {

    /// Returns the `WooShippingUpdateShipmentMapper` output upon receiving `filename` (Data Encoded)
    ///
    func mapShippingLabelConfig(from filename: String) -> WooShippingUpdateShipmentResponse? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! WooShippingUpdateShipmentMapper(siteID: sampleSiteID,
                                                    orderID: sampleOrderID).map(response: response)
    }

    /// Returns the `WooShippingUpdateShipmentMapper` output upon receiving `shipping-label-update-shipment`
    ///
    func mapLoadShippingLabelConfig() -> WooShippingUpdateShipmentResponse? {
        mapShippingLabelConfig(from: "shipping-label-update-shipment")
    }

    /// Returns the `WooShippingUpdateShipmentMapper` output upon receiving `shipping-label-update-shipment-without-data`
    ///
    func mapLoadShippingLabelConfigWithoutDataEnvelope() -> WooShippingUpdateShipmentResponse? {
        mapShippingLabelConfig(from: "shipping-label-update-shipment-without-data")
    }
}
