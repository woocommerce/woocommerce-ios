/// Mapper: NewShipmentTrackingMapper
///
struct NewShipmentTrackingMapper: Mapper {
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

    /// (Attempts) to convert a dictionary into an ShipmentTracking entity.
    ///
    func map(response: Data) throws -> ShipmentTracking {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.yearMonthDayDateFormatter)
        decoder.userInfo = [
            .siteID: siteID,
            .orderID: orderID
        ]
        return try decoder.decode(NewShipmentTrackingMapperEnvelope.self, from: response).shipmentTracking
    }
}

private struct NewShipmentTrackingMapperEnvelope: Decodable {
    let shipmentTracking: ShipmentTracking

    private enum CodingKeys: String, CodingKey {
        case shipmentTracking = "data"
    }
}
