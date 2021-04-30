import Foundation


/// Mapper: Shipping Label Address Validation Response
///
struct ShippingLabelAddressValidationSuccessMapper: Mapper {
    /// (Attempts) to convert a dictionary into ShippingLabelAddressValidationResponse.
    ///
    func map(response: Data) throws -> ShippingLabelAddressValidationSuccess {
        let decoder = JSONDecoder()
        return try decoder.decode(ShippingLabelAddressValidationResponseEnvelope.self, from: response)
            .data
            .result
            .get()
    }
}

/// ShippingLabelAddressValidationResponseEnvelope Disposable Entity:
/// `Normalize Address` endpoint returns the shipping label address document in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ShippingLabelAddressValidationResponseEnvelope: Decodable {
    let data: ShippingLabelAddressValidationResponse

    private enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}
