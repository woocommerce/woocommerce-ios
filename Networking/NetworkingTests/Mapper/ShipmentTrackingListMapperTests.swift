import XCTest
@testable import Networking


/// ShipmentTrackingListMapper Unit Tests
///
final class ShipmentTrackingListMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 424242

    /// Dummy Order ID.
    ///
    private let dummyOrderID: Int64 = 99999999

    /// Verifies that all of the ShipmentTracking Fields are parsed correctly for multiple tracking JSON objects.
    ///
    func test_tracking_fields_are_properly_parsed_for_multiple() {
        let shipmentTrackings = mapLoadMultipleTrackingsResponse()
        XCTAssertEqual(shipmentTrackings.count, 4)

        let firstTracking = shipmentTrackings.first
        let firstTrackingShipDate = DateFormatter.Defaults.yearMonthDayDateFormatter.date(from: "2019-02-15")
        XCTAssertEqual(firstTracking?.siteID, dummySiteID)
        XCTAssertEqual(firstTracking?.orderID, dummyOrderID)
        XCTAssertEqual(firstTracking?.trackingID, "b1b94eecb1eb1c1edf3fa041efffd015")
        XCTAssertEqual(firstTracking?.trackingNumber, "345645674567")
        XCTAssertEqual(firstTracking?.trackingProvider, "USPS")
        XCTAssertEqual(firstTracking?.trackingURL, "https://tools.usps.com/go/TrackConfirmAction_input?qtc_tLabels1=345645674567")
        XCTAssertEqual(firstTracking?.dateShipped, firstTrackingShipDate)

        let lastTracking = shipmentTrackings.last
        XCTAssertEqual(lastTracking?.siteID, dummySiteID)
        XCTAssertEqual(lastTracking?.orderID, dummyOrderID)
        XCTAssertEqual(lastTracking?.trackingID, "2222")
        XCTAssertEqual(lastTracking?.trackingNumber, "asdfasdf7787775756786789")
        XCTAssertNil(lastTracking?.trackingProvider)
        XCTAssertNil(lastTracking?.trackingURL)
        XCTAssertNil(lastTracking?.dateShipped)
    }

    /// Verifies that all of the ShipmentTracking Fields are parsed correctly for a single tracking JSON object.
    ///
    func test_tracking_fields_are_properly_parsed_for_single() {
        let shipmentTrackings = mapLoadSingleTrackingsResponse()
        XCTAssertEqual(shipmentTrackings.count, 1)

        let firstTracking = shipmentTrackings.first
        let firstTrackingShipDate = DateFormatter.Defaults.yearMonthDayDateFormatter.date(from: "2019-12-31")
        XCTAssertEqual(firstTracking?.siteID, dummySiteID)
        XCTAssertEqual(firstTracking?.orderID, dummyOrderID)
        XCTAssertEqual(firstTracking?.trackingID, "sdfgdfgdfsg34534525")
        XCTAssertEqual(firstTracking?.trackingNumber, "456745674567")
        XCTAssertEqual(firstTracking?.trackingProvider, "USPS")
        XCTAssertEqual(firstTracking?.trackingURL, "https://tools.usps.com/go/TrackConfirmAction_input?qtc_tLabels1=456745674567")
        XCTAssertEqual(firstTracking?.dateShipped, firstTrackingShipDate)
    }

    /// Verifies that all of the ShipmentTracking Fields are parsed correctly an empty JSON array.
    ///
    func test_tracking_fields_are_properly_parsed_for_empty() {
        let shipmentTrackings = mapLoadEmptyTrackingsResponse()
        XCTAssertEqual(shipmentTrackings.count, 0)
    }

    /// Verifies that all of the ShipmentTracking Fields are parsed correctly for a single tracking JSON object.
    ///
    func test_tracking_fields_are_properly_parsed_when_response_has_no_data_envelope() {
        let shipmentTrackings = mapLoadSingleTrackingsResponseWithoutDataEnvelope()
        XCTAssertEqual(shipmentTrackings.count, 1)

        let firstTracking = shipmentTrackings.first
        let firstTrackingShipDate = DateFormatter.Defaults.yearMonthDayDateFormatter.date(from: "2019-12-31")
        XCTAssertEqual(firstTracking?.siteID, dummySiteID)
        XCTAssertEqual(firstTracking?.orderID, dummyOrderID)
        XCTAssertEqual(firstTracking?.trackingID, "sdfgdfgdfsg34534525")
        XCTAssertEqual(firstTracking?.trackingNumber, "456745674567")
        XCTAssertEqual(firstTracking?.trackingProvider, "USPS")
        XCTAssertEqual(firstTracking?.trackingURL, "https://tools.usps.com/go/TrackConfirmAction_input?qtc_tLabels1=456745674567")
        XCTAssertEqual(firstTracking?.dateShipped, firstTrackingShipDate)
    }
}


/// Private Methods.
///
private extension ShipmentTrackingListMapperTests {

    /// Returns the ShipmentTrackingsMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapShipmentTrackings(from filename: String) -> [ShipmentTracking] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! ShipmentTrackingListMapper(siteID: dummySiteID, orderID: dummyOrderID).map(response: response)
    }

    /// Returns the ShipmentTrackingsMapper output upon receiving `shipment_tracking_single`
    ///
    func mapLoadSingleTrackingsResponse() -> [ShipmentTracking] {
        return mapShipmentTrackings(from: "shipment_tracking_single")
    }

    /// Returns the ShipmentTrackingsMapper output upon receiving `shipment_tracking_multiple`
    ///
    func mapLoadMultipleTrackingsResponse() -> [ShipmentTracking] {
        return mapShipmentTrackings(from: "shipment_tracking_multiple")
    }

    /// Returns the ShipmentTrackingsMapper output upon receiving `shipment_tracking_empty`
    ///
    func mapLoadEmptyTrackingsResponse() -> [ShipmentTracking] {
        return mapShipmentTrackings(from: "shipment_tracking_empty")
    }

    /// Returns the ShipmentTrackingsMapper output upon receiving `shipment_tracking_single-without-data`
    ///
    func mapLoadSingleTrackingsResponseWithoutDataEnvelope() -> [ShipmentTracking] {
        return mapShipmentTrackings(from: "shipment_tracking_single-without-data")
    }
}
