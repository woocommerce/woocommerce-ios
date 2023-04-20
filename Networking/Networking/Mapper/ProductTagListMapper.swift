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
        let hasDataEnvelope = response.hasDataEnvelope

        switch responseType {
        case .load:
            if hasDataEnvelope {
                return try decoder.decode(ProductTagListEnvelope.self, from: response).tags
            } else {
                return try decoder.decode([ProductTag].self, from: response)
            }
        case .create:
            let tags: [ProductTagFromBatchCreation] = {
                if hasDataEnvelope {
                    return (try? decoder.decode(ProductTagListBatchCreateEnvelope.self, from: response).data.tags) ?? []
                } else {
                    return (try? decoder.decode(ProductTagListBatchCreateContainer.self, from: response).tags) ?? []
                }
            }()
            return tags
                .filter { $0.error == nil }
                .compactMap { (tagCreated) -> ProductTag? in
                    if let name = tagCreated.name, let slug = tagCreated.slug {
                        return ProductTag(siteID: tagCreated.siteID, tagID: tagCreated.tagID, name: name, slug: slug)
                    }
                    return nil
                }

        case .delete:
            if hasDataEnvelope {
                return try decoder.decode(ProductTagListBatchDeleteEnvelope.self, from: response).data.tags
            } else {
                return try decoder.decode(ProductTagListBatchDeleteContainer.self, from: response).tags
            }
        }
    }

    enum ResponseType {
      case load
      case create
      case delete
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


/// ProductTagListBatchCreateEnvelope Disposable Entity:
/// `Batch Create Products Tags` endpoint returns the products tags under the `data` key, nested under `create`  key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ProductTagListBatchCreateEnvelope: Decodable {
    let data: ProductTagListBatchCreateContainer

    private enum CodingKeys: String, CodingKey {
        case data
    }
}

private struct ProductTagListBatchCreateContainer: Decodable {
    let tags: [ProductTagFromBatchCreation]

    private enum CodingKeys: String, CodingKey {
        case tags = "create"
    }
}

/// ProductTagListBatchDeleteEnvelope Disposable Entity:
/// `Batch Delete Products Tags` endpoint returns the products tags under the `data` key, nested under `delete` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ProductTagListBatchDeleteEnvelope: Decodable {
    let data: ProductTagListBatchDeleteContainer

    private enum CodingKeys: String, CodingKey {
        case data
    }
}

private struct ProductTagListBatchDeleteContainer: Decodable {
    let tags: [ProductTag]

    private enum CodingKeys: String, CodingKey {
        case tags = "delete"
    }
}
