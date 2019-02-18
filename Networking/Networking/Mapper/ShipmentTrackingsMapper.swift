import Foundation


/// Mapper: ShipmentTracking (Multiple)
///
struct ShipmentTrackingsMapper: Mapper {

    /// Site Identifier associated to the shipment trackings that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't
    /// really return the siteID for the shipment tracking endpoint
    ///
    let siteID: Int

    /// Order Identifier associated to the shipment trackings that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't
    /// really return the orderID for the shipment tracking endpoint
    ///
    let orderID: Int

    /// (Attempts) to convert a dictionary into [ShipmentTracking]
    ///
    func map(response: Data) throws -> [ShipmentTracking] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.yearMonthDayDateFormatter)
        decoder.userInfo = [
            .siteID: siteID,
            .orderID: orderID
        ]

        return try decoder.decode(ShipmentTrackingsEnvelope.self, from: response).shipmentTrackings
    }
}


/// ShipmentTracking Disposable Entity:
/// `Load Shimpent Trackings` endpoint returns all of its tracking details within the `data` key. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct ShipmentTrackingsEnvelope: Decodable {
    let shipmentTrackings: [ShipmentTracking]

    private enum CodingKeys: String, CodingKey {
        case shipmentTrackings = "data"
    }
}
