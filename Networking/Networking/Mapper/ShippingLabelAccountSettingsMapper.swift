import Foundation

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

        return try decoder.decode(ShippingLabelAccountSettingsMapperEnvelope.self, from: response).data
    }
}

/// ShippingLabelAccountSettingsMapperEnvelope Disposable Entity:
/// `Shipping Label Account Settings` endpoint returns the shipping label account settings in the `data` key.
/// This entity allows us to parse all the things with JSONDecoder.
///
private struct ShippingLabelAccountSettingsMapperEnvelope: Decodable {
    let data: ShippingLabelAccountSettings

    private enum CodingKeys: String, CodingKey {
        case data
    }
}
