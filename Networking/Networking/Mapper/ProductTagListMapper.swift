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

        let decodedResponse = try? decoder.decode(ProductTagListEnvelope.self, from: response)
        let decodedResponseTagsCreate = try? decoder.decode(ProductTagListCreateEnvelope.self, from: response)

        return decodedResponse?.tags ?? decodedResponseTagsCreate?.createdTags ?? []
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


/// ProductTagListCreateEnvelope Disposable Entity:
/// `Load Created Products Tags` endpoint returns the products tags under the `data`->`create` nested key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ProductTagListCreateEnvelope: Decodable {
    let createdTags: [ProductTag]?

    public init(from decoder: Decoder) throws {
        let container = try? decoder.container(keyedBy: CodingKeys.self)
        let nestedContainer = try? container?.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)

        createdTags = nestedContainer?.failsafeDecodeIfPresent(Array<ProductTag>.self, forKey: .create)
    }

    private enum CodingKeys: String, CodingKey {
        case data
        case create
    }
}
