import Foundation
import XCTest
@testable import Networking

final class WooShippingShipmentIDFormatterTests: XCTestCase {

    // MARK: - formattedShipmentID

    func test_formatted_shipment_id_when_id_is_numeric_should_return_formatted_id() {
        // Given
        let sut = WooShippingShipmentIDFormatter.self
        let id = "123456"

        // When
        let formattedID = sut.formattedShipmentID(id)

        // Then
        XCTAssertEqual(formattedID, "shipment_123456")
    }

    func test_formatted_shipment_id_when_id_is_already_formatted_should_return_same_id() {
        // Given
        let sut = WooShippingShipmentIDFormatter.self
        let id = "shipment_123456"

        // When
        let formattedID = sut.formattedShipmentID(id)

        // Then
        XCTAssertEqual(formattedID, "shipment_123456")
    }

    func test_formatted_shipment_id_when_non_numeric_should_return_same_id() {
        // Given
        let sut = WooShippingShipmentIDFormatter.self
        let id = "non-numeric-id"

        // When
        let formattedID = sut.formattedShipmentID(id)

        // Then
        XCTAssertEqual(formattedID, id)
    }
}
