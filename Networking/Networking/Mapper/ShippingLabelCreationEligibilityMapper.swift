struct ShippingLabelCreationEligibilityMapper: Mapper {
    /// (Attempts) to convert a dictionary into ShippingLabelAccountSettings.
    ///
    func map(response: Data) throws -> ShippingLabelCreationEligibilityResponse {
        try extract(from: response)
    }
}
