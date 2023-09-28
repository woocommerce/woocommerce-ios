private typealias ProductIDs = [[String: Int64]]

/// Mapper: Product IDs
///
struct ProductIDMapper: Mapper {

    /// (Attempts) to convert an instance of Data into an array of Product IDs
    ///
    func map(response: Data) throws -> [Int64] {
        let decoder = JSONDecoder()

        let ids: ProductIDs
        if hasDataEnvelope(in: response) {
            ids = try decoder.decode(Envelope<ProductIDs>.self, from: response).data
        } else {
            ids = try decoder.decode(ProductIDs.self, from: response)
        }

        return ids.compactMap { $0["id"] }
    }
}
