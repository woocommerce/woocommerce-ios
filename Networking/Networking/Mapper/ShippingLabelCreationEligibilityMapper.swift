/// Mapper: Shipping Label Creation Eligibility
///
struct ShippingLabelCreationEligibilityMapper: Mapper {
    /// (Attempts) to convert a dictionary into ShippingLabelAccountSettings.
    ///
    func map(response: Data) throws -> ShippingLabelCreationEligibilityResponse {
        try extract(from: response, using: JSONDecoder())
    }
}
