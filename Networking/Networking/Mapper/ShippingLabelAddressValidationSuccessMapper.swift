#if os(iOS)

import Foundation


/// Mapper: Shipping Label Address Validation Response
///
struct ShippingLabelAddressValidationSuccessMapper: Mapper {
    /// (Attempts) to convert a dictionary into ShippingLabelAddressValidationResponse.
    ///
    func map(response: Data) throws -> ShippingLabelAddressValidationSuccess {
        let decoder = JSONDecoder()
        let data: ShippingLabelAddressValidationResponse = try {
            if hasDataEnvelope(in: response) {
                return try decoder.decode(ShippingLabelAddressValidationResponseEnvelope.self, from: response).data
            } else {
                return try decoder.decode(ShippingLabelAddressValidationResponse.self, from: response)
            }
        }()
        return try data.result.get()
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

#endif
