import Foundation


/// Mapper: Shipping Label Create Package response
///
struct WooShippingCreatePackageMapper: Mapper {
    /// (Attempts) to convert a dictionary into WooShippingCreatePackageResponse.
    ///
    func map(response: Data) throws -> WooShippingCreatePackageResponse {
        let decoder = JSONDecoder()
        if hasDataEnvelope(in: response) {
            return try decoder.decode(WooShippingCreatePackageMapperEnvelope.self, from: response).data
        } else {
            return try decoder.decode(WooShippingCreatePackageResponse.self, from: response)
        }
    }
}

/// WooShippingCreatePackageMapperEnvelope Disposable Entity:
/// `Woo Shipping Packages` endpoint returns the shipping label packages in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct WooShippingCreatePackageMapperEnvelope: Decodable {
    let data: WooShippingCreatePackageResponse

    private enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}
