import Foundation

struct WooShippingOriginAddressesMapper: Mapper {

    /// Site ID associated to the origin addresses that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned from the remote.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into WooShippingOriginAddress array.
    ///
    func map(response: Data) throws -> [WooShippingOriginAddress] {
        let decoder = JSONDecoder()
        decoder.userInfo = [.siteID: siteID]
        if hasDataEnvelope(in: response) {
            return try decoder.decode(WooShippingOriginAddressesMapperEnvelope.self, from: response).data
        } else {
            return try decoder.decode([WooShippingOriginAddress].self, from: response)
        }
    }
}

/// WooShippingOriginAddressesMapperEnvelope Disposable Entity:
/// `Woo Shipping Origin Addresses` endpoint returns the shipping label origin addresses in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct WooShippingOriginAddressesMapperEnvelope: Decodable {
    let data: [WooShippingOriginAddress]

    private enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}
