import Foundation

/// Maps the raw WooCommerce core product duplication response to only the duplicated product ID.
struct ProductDuplicateMapper: Mapper {
    func map(response: Data) throws -> Int64 {
        let decoder = JSONDecoder()
        let productID: Int64

        if hasDataEnvelope(in: response) {
            productID = try decoder.decode(ProductDuplicateEnvelope.self, from: response).product.id
        } else {
            productID = try decoder.decode(DuplicatedProduct.self, from: response).id
        }

        guard productID > 0 else {
            throw ProductDuplicateMapperError.invalidProductID
        }
        return productID
    }
}

private enum ProductDuplicateMapperError: Error {
    case invalidProductID
}

private struct DuplicatedProduct: Decodable {
    let id: Int64
}

private struct ProductDuplicateEnvelope: Decodable {
    let product: DuplicatedProduct

    private enum CodingKeys: String, CodingKey {
        case product = "data"
    }
}
