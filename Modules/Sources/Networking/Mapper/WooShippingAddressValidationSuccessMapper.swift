import Foundation


/// Mapper: Shipping Label Address Validation Response from WooCommerce Shipping extension
///
struct WooShippingAddressValidationSuccessMapper: Mapper {
    /// (Attempts) to convert a dictionary into WooShippingAddressValidationResponse.
    ///
    func map(response: Data) throws -> WooShippingAddressValidationSuccess {
        let decoder = JSONDecoder()
        let data: WooShippingAddressValidationResponse = try {
            if hasDataEnvelope(in: response) {
                return try decoder.decode(WooShippingAddressValidationResponseEnvelope.self, from: response).data
            } else {
                return try decoder.decode(WooShippingAddressValidationResponse.self, from: response)
            }
        }()
        return try data.result.get()
    }
}

/// WooShippingAddressValidationResponseEnvelope Disposable Entity:
/// `Normalize Address` endpoint returns the shipping label address document in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct WooShippingAddressValidationResponseEnvelope: Decodable {
    let data: WooShippingAddressValidationResponse

    private enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}
