import Foundation


/// Mapper: Order
///
struct ProductMapper: Mapper {

    /// Site Identifier associated to the orders that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't really return the SiteID in any of the
    /// Order Endpoints.
    ///
    let siteID: Int


    /// (Attempts) to convert a dictionary into Product.
    ///
    func map(response: Data) throws -> Product {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try decoder.decode(ProductEnvelope.self, from: response).product
    }
}


/// OrdersEnvelope Disposable Entity:
/// `Update Order` endpoint returns the updated order document in the `data` key. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct ProductEnvelope: Decodable {
    let product: Product

    private enum CodingKeys: String, CodingKey {
        case product = "data"
    }
}
