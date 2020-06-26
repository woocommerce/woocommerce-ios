import Foundation


/// Mapper: ProductTag
///
struct ProductTagMapper: Mapper {

    /// Site Identifier associated to the `ProductTag`s that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the ProductTag Endpoints.
    ///
    let siteID: Int64


    /// (Attempts) to convert a dictionary into ProductTag.
    ///
    func map(response: Data) throws -> ProductTag {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try decoder.decode(ProductTagEnvelope.self, from: response).tag
    }
}


/// ProductTagEnvelope Disposable Entity:
/// `Load Product Tag` endpoint returns the updated tag document in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ProductTagEnvelope: Decodable {
    let tag: ProductTag

    private enum CodingKeys: String, CodingKey {
        case tag = "data"
    }
}
