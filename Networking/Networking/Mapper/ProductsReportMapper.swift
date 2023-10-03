/// Mapper: `[ProductsReportItem]`
///
struct ProductsReportMapper: Mapper {

    /// (Attempts) to convert a dictionary into `[ProductsReportItem]`.
    ///
    func map(response: Data) throws -> [ProductsReportItem] {
        let decoder = JSONDecoder()
        if hasDataEnvelope(in: response) {
            return try decoder.decode(Envelope<[ProductsReportItem]>.self, from: response).data
        } else {
            return try decoder.decode([ProductsReportItem].self, from: response)
        }
    }
}
