import Foundation

/// Mapper: ProductTag List
///
struct ProductTagListMapper: Mapper {
    /// Site Identifier associated to the `ProductTags`s that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the ProductTag Endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into [ProductTag].
    ///
    func map(response: Data) throws -> [ProductTag] {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try decoder.decode(ProductTagListEnvelope.self, from: response).tags
    }
}


/// ProductTagListEnvelope Disposable Entity:
/// `Load All Products Tags` endpoint returns the products tags in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ProductTagListEnvelope: Decodable {
    let tags: [ProductTag]

    private enum CodingKeys: String, CodingKey {
        case tags = "data"
    }
}
