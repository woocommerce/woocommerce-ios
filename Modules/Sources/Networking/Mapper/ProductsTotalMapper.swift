import Foundation

/// Mapper: ProductsTotal
///
struct ProductsTotalMapper: Mapper {
    func map(response: Data) throws -> Int64 {
        let decoder = JSONDecoder()
        let totals: [ProductTypeTotal]

        if hasDataEnvelope(in: response) {
            totals = try decoder
                .decode(ProductTypeTotalListEnvelope.self, from: response)
                .totals
        } else {
            totals = try decoder.decode([ProductTypeTotal].self, from: response)
        }
        return totals.map { $0.total }.reduce(0, +)
    }
}

private struct ProductTypeTotal: Decodable {
    let total: Int64

    private enum CodingKeys: String, CodingKey {
        case total
    }
}

private struct ProductTypeTotalListEnvelope: Decodable {
    let totals: [ProductTypeTotal]

    private enum CodingKeys: String, CodingKey {
        case totals = "data"
    }
}
