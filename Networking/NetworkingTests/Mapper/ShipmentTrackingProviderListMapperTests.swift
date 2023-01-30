import XCTest
@testable import Networking

/// ShipmentTrackingProviderListMapper Unit Tests
///
final class ShipmentTrackingProviderListMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 424242

    func test_provider_fields_are_properly_parsed() throws {
        let shipmentTrackingProviders = try mapLoadShipmentTrackingProviderResponse()
        XCTAssertEqual(shipmentTrackingProviders.count, 19)

        let shipmentProviderGroup = try XCTUnwrap(shipmentTrackingProviders.first(where:) { $0.name ==  "Australia" })

        XCTAssertEqual(shipmentProviderGroup.providers.count, 2)
        XCTAssertTrue(shipmentProviderGroup.providers.contains(where: { $0.name == "Australia Post" }))
        XCTAssertTrue(shipmentProviderGroup.providers.contains(where: { $0.name == "Fastway Couriers" }))
    }

    func test_provider_fields_are_properly_parsed_when_response_has_no_data_envelope() throws {
        let shipmentTrackingProviders = try mapLoadShipmentTrackingProviderResponseWithoutDataEnvelope()
        XCTAssertEqual(shipmentTrackingProviders.count, 19)

        let shipmentProviderGroup = try XCTUnwrap(shipmentTrackingProviders.first(where:) { $0.name ==  "Australia" })

        XCTAssertEqual(shipmentProviderGroup.providers.count, 2)
        XCTAssertTrue(shipmentProviderGroup.providers.contains(where: { $0.name == "Australia Post" }))
        XCTAssertTrue(shipmentProviderGroup.providers.contains(where: { $0.name == "Fastway Couriers" }))
    }
}

/// Private Methods.
///
private extension ShipmentTrackingProviderListMapperTests {

    /// Returns the ShipmentTrackingProviderListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapShipmentTrackingProvider(from filename: String) throws -> [ShipmentTrackingProviderGroup] {
        guard let response = Loader.contentsOf(filename) else {
            throw ParsingError.unableToLoadFile
        }

        return try! ShipmentTrackingProviderListMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the ShipmentTrackingProviderListMapper output upon receiving `shipment_tracking_providers`
    ///
    func mapLoadShipmentTrackingProviderResponse() throws -> [ShipmentTrackingProviderGroup] {
        try mapShipmentTrackingProvider(from: "shipment_tracking_providers")
    }

    /// Returns the ShipmentTrackingProviderListMapper output upon receiving `shipment_tracking_providers_without_data`
    ///
    func mapLoadShipmentTrackingProviderResponseWithoutDataEnvelope() throws -> [ShipmentTrackingProviderGroup] {
        try mapShipmentTrackingProvider(from: "shipment_tracking_providers_without_data")
    }
}

private enum ParsingError: Error {
    case unableToLoadFile
}
