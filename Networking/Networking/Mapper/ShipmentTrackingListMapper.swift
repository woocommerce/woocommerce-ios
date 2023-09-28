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

        if hasDataEnvelope(in: response) {
            return try decoder.decode(Envelope<[ShipmentTracking]>.self, from: response).data
        } else {
            return try decoder.decode([ShipmentTracking].self, from: response)
        }
    }
}
