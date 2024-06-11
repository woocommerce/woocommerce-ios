import Foundation

/// Mapper: ShippingMethod List
///
struct ShippingMethodListMapper: Mapper {
    /// Site Identifier associated to the order that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in the endpoints used to retrieve ShippingMethod models.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into ShippingMethod.
    ///
    func map(response: Data) throws -> [ShippingMethod] {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]

        if hasDataEnvelope(in: response) {
            return try decoder.decode(ShippingMethodEnvelope.self, from: response).methods
        } else {
            return try decoder.decode([ShippingMethod].self, from: response)
        }
    }
}

/// UserEnvelope Disposable Entity
///
/// `Fetch Shipping Methods` endpoint returns the requested objects in the `data` key. This entity
/// allows us to parse all the things with JSONDecoder.
///
private struct ShippingMethodEnvelope: Decodable {
    let methods: [ShippingMethod]

    private enum CodingKeys: String, CodingKey {
        case methods = "data"
    }
}
