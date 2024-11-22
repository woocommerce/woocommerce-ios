import Foundation

/// Mapper: WooShipping Account Settings
///
struct WooShippingAccountSettingsMapper: Mapper {
    /// Site Identifier associated to the stats that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't return the SiteID.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into WooShippingAccountSettingsResponse.
    ///
    func map(response: Data) throws -> WooShippingAccountSettingsResponse {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.yearMonthDayDateFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        if hasDataEnvelope(in: response) {
            return try decoder.decode(WooShippingAccountSettingsMapperEnvelope.self, from: response).data
        } else {
            return try decoder.decode(WooShippingAccountSettingsResponse.self, from: response)
        }
    }
}

/// WooShippingAccountSettingsMapperEnvelope Disposable Entity:
/// `WooShipping Account Settings` endpoint returns the shipping label account settings in the `data` key.
/// This entity allows us to parse all the things with JSONDecoder.
///
private struct WooShippingAccountSettingsMapperEnvelope: Decodable {
    let data: WooShippingAccountSettingsResponse

    private enum CodingKeys: String, CodingKey {
        case data
    }
}
