/// Mapper: Shipping Label Packages
///
struct ShippingLabelPackagesMapper: Mapper {
    /// (Attempts) to convert a dictionary into ShippingLabelPackagesResponse.
    ///
    func map(response: Data) throws -> ShippingLabelPackagesResponse {
        try extract(from: response, using: JSONDecoder())
    }
}
