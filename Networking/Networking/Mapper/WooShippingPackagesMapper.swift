import Foundation

struct WooShippingPackagesMapper: Mapper {
    /// Site Identifier associated to the order that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Order Endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into WooShippingPackagesResponse.
    ///
    func map(response: Data) throws -> WooShippingPackagesResponse {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]
        if hasDataEnvelope(in: response) {
            return try decoder.decode(WooShippingPackagesMapperEnvelope.self, from: response).data
        } else {
            return try decoder.decode(WooShippingPackagesResponse.self, from: response)
        }
    }
}

/// WooShippingPackagesMapperEnvelope Disposable Entity:
/// `Woo Shipping Packages` endpoint returns the shipping label packages in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct WooShippingPackagesMapperEnvelope: Decodable {
    let data: WooShippingPackagesResponse

    private enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}
