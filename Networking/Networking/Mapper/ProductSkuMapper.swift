/// Mapper: Product Sku String
///
struct ProductSkuMapper: Mapper {

    /// (Attempts) to convert an instance of Data into a Product Sku string
    ///
    func map(response: Data) throws -> String {
        let decoder = JSONDecoder()

        let skus: ProductsSKUs
        if hasDataEnvelope(in: response) {
            skus = try decoder.decode(Envelope<ProductsSKUs>.self, from: response).data
        } else {
            skus = try decoder.decode(ProductsSKUs.self, from: response)
        }

        return skus.first?["sku"] ?? ""
    }
}

typealias ProductsSKUs = [[String: String]]
