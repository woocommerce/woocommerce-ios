import Foundation

/// Mapper: Shipping Label Creation Eligibility
///
struct ShippingLabelCreationEligibilityMapper: Mapper {
    /// (Attempts) to convert a dictionary into ShippingLabelAccountSettings.
    ///
    func map(response: Data) throws -> ShippingLabelCreationEligibilityResponse {
        let decoder = JSONDecoder()
        return try decoder.decode(ShippingLabelCreationEligibilityMapperEnvelope.self, from: response).eligibility
    }
}

/// ShippingLabelCreationEligibilityMapperEnvelope Disposable Entity:
/// `Shipping Label Creation Eligibility` endpoint returns the shipping label account settings in the `data` key.
/// This entity allows us to parse all the things with JSONDecoder.
///
private struct ShippingLabelCreationEligibilityMapperEnvelope: Decodable {
    let eligibility: ShippingLabelCreationEligibilityResponse

    private enum CodingKeys: String, CodingKey {
        case eligibility = "data"
    }
}
