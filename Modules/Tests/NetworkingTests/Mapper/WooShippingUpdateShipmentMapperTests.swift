import XCTest
@testable import Networking
@testable import NetworkingCore

/// Unit Tests for `WooShippingUpdateShipmentMapper`
///
final class WooShippingUpdateShipmentMapperTests: XCTestCase {
    func test_shipments_are_properly_parsed() throws {
        guard let shipments = mapLoadShippingLabelConfig() else {
            XCTFail()
            return
        }

        XCTAssertEqual(shipments.count, 3)
        let shipment = try XCTUnwrap(shipments["0"])

        let shipmentItem = try XCTUnwrap(shipment.first)
        XCTAssertEqual(shipmentItem.id, 209)
        XCTAssertEqual(shipmentItem.subItems, ["209-sub-0", "209-sub-1", "209-sub-2"])
    }

    func test_shipments_are_properly_parsed_when_response_has_no_data_envelope() throws {
        guard let shipments = mapLoadShippingLabelConfigWithoutDataEnvelope() else {
            XCTFail()
            return
        }

        XCTAssertEqual(shipments.count, 3)
        let shipment = try XCTUnwrap(shipments["1"])

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
    func mapShippingLabelConfig(from filename: String) -> WooShippingShipments? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! WooShippingUpdateShipmentMapper().map(response: response)
    }

    /// Returns the `WooShippingUpdateShipmentMapper` output upon receiving `shipping-label-update-shipment`
    ///
    func mapLoadShippingLabelConfig() -> WooShippingShipments? {
        mapShippingLabelConfig(from: "shipping-label-update-shipment")
    }

    /// Returns the `WooShippingUpdateShipmentMapper` output upon receiving `shipping-label-update-shipment-without-data`
    ///
    func mapLoadShippingLabelConfigWithoutDataEnvelope() -> WooShippingShipments? {
        mapShippingLabelConfig(from: "shipping-label-update-shipment-without-data")
    }
}
