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
        if response.hasDataEnvelope {
            return try decoder.decode(ProductsEnvelope.self, from: response).data.updatedProducts
        } else {
            return try decoder.decode(ProductsContainer.self, from: response).updatedProducts
        }
    }
}

/// ProductsEnvelope Disposable Entity
///
/// `products/batch` endpoint returns the requested updated products in a `update` key, nested in a `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ProductsEnvelope: Decodable {
    let data: ProductsContainer

    private enum CodingKeys: String, CodingKey {
        case data
    }
}

private struct ProductsContainer: Decodable {
    let updatedProducts: [Product]

    private enum CodingKeys: String, CodingKey {
        case updatedProducts = "update"
    }
}
