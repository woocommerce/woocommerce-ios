import Foundation

struct WooShippingOriginAddressesMapper: Mapper {
    /// (Attempts) to convert a dictionary into WooShippingLabelAddress array.
    ///
    func map(response: Data) throws -> [WooShippingLabelAddress] {
        let decoder = JSONDecoder()
        if hasDataEnvelope(in: response) {
            return try decoder.decode(WooShippingOriginAddressesMapperEnvelope.self, from: response).data
        } else {
            return try decoder.decode([WooShippingLabelAddress].self, from: response)
        }
    }
}

/// WooShippingOriginAddressesMapperEnvelope Disposable Entity:
/// `Woo Shipping Origin Addresses` endpoint returns the shipping label origin addresses in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct WooShippingOriginAddressesMapperEnvelope: Decodable {
    let data: [WooShippingLabelAddress]

    private enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}
