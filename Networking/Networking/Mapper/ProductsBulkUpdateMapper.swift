/// Mapper: ProductsBulkUpdateMapper
///
struct ProductsBulkUpdateMapper: Mapper {
    /// Site Identifier associated to the products that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Product Endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into Products.
    ///
    func map(response: Data) throws -> [Product] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        if hasDataEnvelope(in: response) {
            return try decoder.decode(Envelope<ProductsContainer>.self, from: response).data.updatedProducts
        } else {
            return try decoder.decode(ProductsContainer.self, from: response).updatedProducts
        }
    }
}

private struct ProductsContainer: Decodable {
    let updatedProducts: [Product]

    private enum CodingKeys: String, CodingKey {
        case updatedProducts = "update"
    }
}
