import Foundation

/// Mapper: Verify Destination Address Response from WooCommerce Shipping extension
///
struct WooShippingVerifyDestinationAddressMapper: Mapper {
    /// (Attempts) to convert a dictionary into WooShippingVerifyDestinationAddressResponse.
    ///
    func map(response: Data) throws -> WooShippingVerifyDestinationAddressSuccess {
        let decoder = JSONDecoder()
        let data: WooShippingVerifyDestinationAddressResponse = try {
            if hasDataEnvelope(in: response) {
                return try decoder.decode(WooShippingVerifyDestinationAddressResponseEnvelope.self, from: response).data
            } else {
                return try decoder.decode(WooShippingVerifyDestinationAddressResponse.self, from: response)
            }
        }()
        return try data.result.get()
    }
}

/// WooShippingVerifyDestinationAddressResponseEnvelope Disposable Entity:
/// `Veridy Destination Address` endpoint returns the shipping label address document in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct WooShippingVerifyDestinationAddressResponseEnvelope: Decodable {
    let data: WooShippingVerifyDestinationAddressResponse

    private enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}
