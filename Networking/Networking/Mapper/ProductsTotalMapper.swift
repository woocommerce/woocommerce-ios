/// Mapper: ProductsTotal
///
struct ProductsTotalMapper: Mapper {
    func map(response: Data) throws -> Int64 {
        let decoder = JSONDecoder()

        let totals: [ProductTypeTotal]
        if hasDataEnvelope(in: response) {
            totals = try decoder .decode(Envelope<[ProductTypeTotal]>.self, from: response).data
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
