import Foundation

/// Mapper: Product IDs
///
struct ProductIDMapper: Mapper {

    /// (Attempts) to convert an instance of Data into an array of Product IDs
    ///
    func map(response: Data) throws -> [Int64] {
        let decoder = JSONDecoder()

        return try decoder.decode(ProductIDEnvelope.self, from: response).productIDs.compactMap { $0["id"] }
    }
}


/// ProductIDEnvelope Disposable Entity:
/// `Products` endpoint returns if a product exists. This entity
/// allows us to parse the product IDs with JSONDecoder.
///
private struct ProductIDEnvelope: Decodable {
    let productIDs: [[String: Int64]]

    private enum CodingKeys: String, CodingKey {
        case productIDs = "data"
    }
}
