#if os(iOS)

import Foundation


/// Mapper: Shipping Label Packages
///
struct ShippingLabelPackagesMapper: Mapper {
    /// (Attempts) to convert a dictionary into ShippingLabelPackagesResponse.
    ///
    func map(response: Data) throws -> ShippingLabelPackagesResponse {
        let decoder = JSONDecoder()
        if hasDataEnvelope(in: response) {
            return try decoder.decode(ShippingLabelPackagesMapperEnvelope.self, from: response).data
        } else {
            return try decoder.decode(ShippingLabelPackagesResponse.self, from: response)
        }
    }
}

/// ShippingLabelPackagesMapperEnvelope Disposable Entity:
/// `Shipping Label Packages` endpoint returns the shipping label packages in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ShippingLabelPackagesMapperEnvelope: Decodable {
    let data: ShippingLabelPackagesResponse

    private enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}

#endif
