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
        let decodedResponseBatchUpdatedTags = try? decoder.decode(ProductTagListBatchUpdateEnvelope.self, from: response)

        return decodedResponse?.tags ??
            decodedResponseBatchUpdatedTags?.createdTags ??
            decodedResponseBatchUpdatedTags?.deletedTags ?? []
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


/// ProductTagListBatchUpdateEnvelope Disposable Entity:
/// `Batch update Products Tags` endpoint returns the products tags under the `data` key, nested under `create` or `delete` keys.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ProductTagListBatchUpdateEnvelope: Decodable {
    let createdTags: [ProductTag]?
    let deletedTags: [ProductTag]?

    public init(from decoder: Decoder) throws {
        let container = try? decoder.container(keyedBy: CodingKeys.self)
        let nestedContainer = try? container?.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)

        createdTags = nestedContainer?.failsafeDecodeIfPresent(Array<ProductTag>.self, forKey: .create)
        deletedTags = nestedContainer?.failsafeDecodeIfPresent(Array<ProductTag>.self, forKey: .delete)
    }

    private enum CodingKeys: String, CodingKey {
        case data
        case create
        case delete
    }
}
