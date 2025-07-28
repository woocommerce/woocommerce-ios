import Foundation

/// Mapper: `[ProductsReportItem]`
///
struct ProductsReportMapper: Mapper {

    /// (Attempts) to convert a dictionary into `[ProductsReportItem]`.
    ///
    func map(response: Data) throws -> [ProductsReportItem] {
        let decoder = JSONDecoder()
        if hasDataEnvelope(in: response) {
            return try decoder.decode(ProductsReportEnvelope.self, from: response).items
        } else {
            return try decoder.decode([ProductsReportItem].self, from: response)
        }
    }
}


/// ProductsReportEnvelope Disposable Entity:
/// Load Products Report endpoint returns the coupon in the `data` key.
/// This entity allows us to parse all the things with JSONDecoder.
///
private struct ProductsReportEnvelope: Decodable {
    let items: [ProductsReportItem]

    private enum CodingKeys: String, CodingKey {
        case items = "data"
    }
}
