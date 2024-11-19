import Foundation

/// Mapper: WooShipping Account Settings
///
struct WooShippingAccountSettingsMapper: Mapper {
    /// (Attempts) to convert a dictionary into WooShippingAccountSettingsResponse.
    ///
    func map(response: Data) throws -> WooShippingAccountSettingsResponse {
        let decoder = JSONDecoder()

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
