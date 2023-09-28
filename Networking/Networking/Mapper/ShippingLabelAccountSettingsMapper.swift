/// Mapper: Shipping Label Account Settings
///
struct ShippingLabelAccountSettingsMapper: Mapper {
    /// Site Identifier associated to the stats that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't return the SiteID.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into ShippingLabelAccountSettings.
    ///
    func map(response: Data) throws -> ShippingLabelAccountSettings {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.yearMonthDayDateFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        if hasDataEnvelope(in: response) {
            return try decoder.decode(Envelope<ShippingLabelAccountSettings>.self, from: response).data
        } else {
            return try decoder.decode(ShippingLabelAccountSettings.self, from: response)
        }
    }
}
