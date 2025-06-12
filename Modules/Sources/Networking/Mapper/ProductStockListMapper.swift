import Foundation

/// Mapper: `[ProductStock]`
///
struct ProductStockListMapper: Mapper {
    /// Site Identifier associated to the products that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Product Endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into `[ProductStock]`.
    ///
    func map(response: Data) throws -> [ProductStock] {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]
        if hasDataEnvelope(in: response) {
            return try decoder.decode(ProductStockListEnvelope.self, from: response).items
        } else {
            return try decoder.decode([ProductStock].self, from: response)
        }
    }
}


/// ProductStockListEnvelope Disposable Entity:
/// Load Product stock list endpoint returns the stock in the `data` key.
/// This entity allows us to parse all the things with JSONDecoder.
///
private struct ProductStockListEnvelope: Decodable {
    let items: [ProductStock]

    private enum CodingKeys: String, CodingKey {
        case items = "data"
    }
}
