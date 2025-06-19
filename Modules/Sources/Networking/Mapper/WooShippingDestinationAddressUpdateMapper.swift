import Foundation

struct WooShippingDestinationAddressUpdateMapper: Mapper {
    /// (Attempts) to convert a dictionary into a WooShippingDestinationAddressUpdate.
    ///
    func map(response: Data) throws -> WooShippingDestinationAddressUpdate {
        let decoder = JSONDecoder()
        if hasDataEnvelope(in: response) {
            return try decoder.decode(WooShippingDestinationAddressUpdateMapperEnvelope.self, from: response).data
        } else {
            return try decoder.decode(WooShippingDestinationAddressUpdate.self, from: response)
        }
    }
}

/// WooShippingDestinationAddressUpdateMapperEnvelope Disposable Entity:
/// `Woo Shipping Update Destination Address` endpoint returns the updated data in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct WooShippingDestinationAddressUpdateMapperEnvelope: Decodable {
    let data: WooShippingDestinationAddressUpdate

    private enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}
