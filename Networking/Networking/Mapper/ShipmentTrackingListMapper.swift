import Foundation


/// Mapper for an array of `ShipmentTracking` JSON objects
///
struct ShipmentTrackingListMapper: Mapper {

    /// Site Identifier associated to the shipment trackings that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't
    /// really return the siteID for the shipment tracking endpoint
    ///
    let siteID: Int64

    /// Order Identifier associated to the shipment trackings that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't
    /// really return the orderID for the shipment tracking endpoint
    ///
    let orderID: Int64

    /// (Attempts) to convert a dictionary into [ShipmentTracking]
    ///
    func map(response: Data) throws -> [ShipmentTracking] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.yearMonthDayDateFormatter)
        decoder.userInfo = [
            .siteID: siteID,
            .orderID: orderID
        ]

        return try decoder.decode(ShipmentTrackingListEnvelope.self, from: response).shipmentTrackings
    }
}


/// ShipmentTracking list disposable entity:
/// `Load Shipment Trackings` endpoint returns all of its tracking details within the `data` key. This entity
/// allows us to parse all the things with JSONDecoder.
///
private struct ShipmentTrackingListEnvelope: Decodable {
    let shipmentTrackings: [ShipmentTracking]

    private enum CodingKeys: String, CodingKey {
        case shipmentTrackings = "data"
    }
}
