import XCTest
@testable import Networking

/// NewShipmentTrackingMapper Unit Tests
///
final class NewShipmentTrackingMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 424242

    /// Dummy Order ID.
    ///
    private let dummyOrderID: Int64 = 99999999

    func test_tracking_fields_are_properly_parsed() throws {
        let shipmentTracking = try mapLoadShipmentTrackingResponse()
        let shipmentTrackingShipDate = DateFormatter.Defaults.yearMonthDayDateFormatter.date(from: "2019-03-12")
        XCTAssertEqual(shipmentTracking.siteID, dummySiteID)
        XCTAssertEqual(shipmentTracking.orderID, dummyOrderID)
        XCTAssertEqual(shipmentTracking.trackingID, "f2e7783b40837b9e1ec503a149dab4a1")
        XCTAssertEqual(shipmentTracking.trackingNumber, "123456781234567812345678")
        XCTAssertEqual(shipmentTracking.trackingProvider, "TNT Express (consignment)")
        XCTAssertEqual(shipmentTracking.trackingURL, "http://www.tnt.com/webtracker/tracking")
        XCTAssertEqual(shipmentTracking.dateShipped, shipmentTrackingShipDate)
    }

    func test_tracking_fields_are_properly_parsed_when_response_has_no_data_envelope() throws {
        let shipmentTracking = try mapLoadShipmentTrackingResponseWithoutDataEnvelope()
        let shipmentTrackingShipDate = DateFormatter.Defaults.yearMonthDayDateFormatter.date(from: "2019-03-12")
        XCTAssertEqual(shipmentTracking.siteID, dummySiteID)
        XCTAssertEqual(shipmentTracking.orderID, dummyOrderID)
        XCTAssertEqual(shipmentTracking.trackingID, "f2e7783b40837b9e1ec503a149dab4a1")
        XCTAssertEqual(shipmentTracking.trackingNumber, "123456781234567812345678")
        XCTAssertEqual(shipmentTracking.trackingProvider, "TNT Express (consignment)")
        XCTAssertEqual(shipmentTracking.trackingURL, "http://www.tnt.com/webtracker/tracking")
        XCTAssertEqual(shipmentTracking.dateShipped, shipmentTrackingShipDate)
    }
}


/// Private Methods.
///
private extension NewShipmentTrackingMapperTests {

    /// Returns the NewShipmentTrackingMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapShipmentTracking(from filename: String) throws -> ShipmentTracking {
        guard let response = Loader.contentsOf(filename) else {
            throw ParsingError.unableToLoadFile
        }

        return try! NewShipmentTrackingMapper(siteID: dummySiteID, orderID: dummyOrderID).map(response: response)
    }

    /// Returns the NewShipmentTrackingMapper output upon receiving `shipment_tracking_new`
    ///
    func mapLoadShipmentTrackingResponse() throws -> ShipmentTracking {
        try mapShipmentTracking(from: "shipment_tracking_new")
    }

    /// Returns the NewShipmentTrackingMapper output upon receiving `shipment_tracking_new-without-data`
    ///
    func mapLoadShipmentTrackingResponseWithoutDataEnvelope() throws -> ShipmentTracking {
        try mapShipmentTracking(from: "shipment_tracking_new-without-data")
    }
}

private enum ParsingError: Error {
    case unableToLoadFile
}
