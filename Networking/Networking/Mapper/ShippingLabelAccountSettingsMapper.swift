import Foundation

/// Mapper: Shipping Label Account Settings
///
struct ShippingLabelAccountSettingsMapper: Mapper {
    /// (Attempts) to convert a dictionary into ShippingLabelAccountSettings.
    ///
    func map(response: Data) throws -> ShippingLabelAccountSettings {
        let decoder = JSONDecoder()
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
