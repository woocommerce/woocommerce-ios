import Foundation

struct WooShippingOriginAddressUpdateMapper: Mapper {
    /// (Attempts) to convert a dictionary into a WooShippingOriginAddressUpdate.
    ///
    func map(response: Data) throws -> WooShippingOriginAddressUpdate {
        let decoder = JSONDecoder()
        if hasDataEnvelope(in: response) {
            return try decoder.decode(WooShippingOriginAddressUpdateMapperEnvelope.self, from: response).data
        } else {
            return try decoder.decode(WooShippingOriginAddressUpdate.self, from: response)
        }
    }
}

/// WooShippingOriginAddressUpdateMapperEnvelope Disposable Entity:
/// `Woo Shipping Update Origin Address` endpoint returns the updated data in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct WooShippingOriginAddressUpdateMapperEnvelope: Decodable {
    let data: WooShippingOriginAddressUpdate

    private enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}
