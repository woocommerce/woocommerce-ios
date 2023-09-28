/// Mapper: Product
///
struct ProductMapper: Mapper {

    /// Site Identifier associated to the product that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Product Endpoints.
    ///
    let siteID: Int64


    /// (Attempts) to convert a dictionary into Product.
    ///
    func map(response: Data) throws -> Product {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try extract(from: response, using: decoder)
    }
}
