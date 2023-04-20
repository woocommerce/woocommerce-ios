import Foundation

/// Mapper: Product IDs
///
struct ProductIDMapper: Mapper {

    /// (Attempts) to convert an instance of Data into an array of Product IDs
    ///
    func map(response: Data) throws -> [Int64] {
        let decoder = JSONDecoder()

        if response.hasDataEnvelope {
            return try decoder.decode(ProductIDEnvelope.self, from: response).productIDs.compactMap { $0[Constants.idKey] }
        } else {
            return try decoder.decode(ProductIDEnvelope.ProductIDs.self, from: response).compactMap { $0[Constants.idKey] }
        }
    }
}

// MARK: Constants
//
private extension ProductIDMapper {
    enum Constants {
        static let idKey = "id"
    }
}

/// ProductIDEnvelope Disposable Entity:
/// `Products` endpoint returns if a product exists. This entity
/// allows us to parse the product IDs with JSONDecoder.
///
private struct ProductIDEnvelope: Decodable {
    typealias ProductIDs = [[String: Int64]]

    let productIDs: ProductIDs

    private enum CodingKeys: String, CodingKey {
        case productIDs = "data"
    }
}
