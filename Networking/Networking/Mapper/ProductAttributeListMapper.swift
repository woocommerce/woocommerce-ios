/// Mapper: ProductAttribute List
///
struct ProductAttributeListMapper: Mapper {
    /// Site Identifier associated to the `ProductAttribute`s that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the ProductAttribute Endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into [ProductAttribute].
    ///
    func map(response: Data) throws -> [ProductAttribute] {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try extract(from: response, using: decoder)
    }
}
