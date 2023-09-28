/// Mapper: ProductVariationsBulkCreateMapper
///
struct ProductVariationsBulkCreateMapper: Mapper {
    /// Site Identifier associated to the product variation that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Product Variation Endpoints.
    ///
    let siteID: Int64

    /// Product Identifier associated to the product variation that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because ProductID is not returned in any of the Product Variation Endpoints.
    ///
    let productID: Int64

    /// (Attempts) to convert a dictionary into ProductVariations.
    ///
    func map(response: Data) throws -> [ProductVariation] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID,
            .productID: productID
        ]

        let container: ProductVariationsContainer
        if hasDataEnvelope(in: response) {
            container = try decoder.decode(Envelope<ProductVariationsContainer>.self, from: response).data
        } else {
            container = try decoder.decode(ProductVariationsContainer.self, from: response)
        }

        return container.createdProductVariations
    }
}

private struct ProductVariationsContainer: Decodable {
    let createdProductVariations: [ProductVariation]

    private enum CodingKeys: String, CodingKey {
        case createdProductVariations = "create"
    }
}
