import Foundation

/// Mapper: ProductsBulkUpdateMapper
///
struct ProductsBulkUpdateMapper: Mapper {
    /// Site Identifier associated to the products that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Product Endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into Products.
    ///
    func map(response: Data) throws -> [Product] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]
        return try decoder.decode(ProductsEnvelope.self, from: response).updatedProducts
    }
}

/// ProductsEnvelope Disposable Entity
///
/// `products/batch` endpoint returns the requested updated products in a `update` key, nested in a `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ProductsEnvelope: Decodable {
    let updatedProducts: [Product]

    private enum CodingKeys: String, CodingKey {
        case update
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        do {
            let nestedContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
            updatedProducts = try nestedContainer.decode([Product].self, forKey: .update)
        } catch {
            updatedProducts = try container.decode([Product].self, forKey: .update)
        }
    }
}
