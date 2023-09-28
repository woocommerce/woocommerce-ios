import Foundation

/// Mapper: ProductTag List
///
struct ProductTagListMapper: Mapper {
    /// Site Identifier associated to the `ProductTags`s that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the ProductTag Endpoints.
    ///
    let siteID: Int64

    let responseType: ResponseType

    /// (Attempts) to convert a dictionary into [ProductTag].
    ///
    func map(response: Data) throws -> [ProductTag] {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]
        let hasDataEnvelope = hasDataEnvelope(in: response)

        switch responseType {
        case .load:
            return try extract(from: response, usingJSONDecoderSiteID: siteID)
        case .create:
            let container: ProductTagListBatchCreateContainer
            if hasDataEnvelope {
                container = try decoder.decode(Envelope<ProductTagListBatchCreateContainer>.self, from: response).data
            } else {
                container = try decoder.decode(ProductTagListBatchCreateContainer.self, from: response)
            }

            return container.tags
                .filter { $0.error == nil }
                .compactMap { (tagCreated) -> ProductTag? in
                    if let name = tagCreated.name, let slug = tagCreated.slug {
                        return ProductTag(siteID: tagCreated.siteID, tagID: tagCreated.tagID, name: name, slug: slug)
                    }
                    return nil
                }

        case .delete:
            let container: ProductTagListBatchDeleteContainer
            if hasDataEnvelope {
                container = try decoder.decode(Envelope<ProductTagListBatchDeleteContainer>.self, from: response).data
            } else {
                container = try decoder.decode(ProductTagListBatchDeleteContainer.self, from: response)
            }

            return container.tags
        }
    }

    enum ResponseType {
      case load
      case create
      case delete
    }
}

private struct ProductTagListBatchCreateContainer: Decodable {
    let tags: [ProductTagFromBatchCreation]

    private enum CodingKeys: String, CodingKey {
        case tags = "create"
    }
}

private struct ProductTagListBatchDeleteContainer: Decodable {
    let tags: [ProductTag]

    private enum CodingKeys: String, CodingKey {
        case tags = "delete"
    }
}
