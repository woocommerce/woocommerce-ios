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
        return try extract(
            from: response,
            decodingUserInfo: [
                .siteID: siteID,
                .orderID: orderID
            ],
            dateFormatter: DateFormatter.Defaults.yearMonthDayDateFormatter
        )
    }
}
