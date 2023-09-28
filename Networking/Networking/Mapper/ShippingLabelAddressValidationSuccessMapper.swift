/// Mapper: Shipping Label Address Validation Response
///
struct ShippingLabelAddressValidationSuccessMapper: Mapper {
    /// (Attempts) to convert a dictionary into ShippingLabelAddressValidationResponse.
    ///
    func map(response: Data) throws -> ShippingLabelAddressValidationSuccess {
        let decoder = JSONDecoder()

        let data: ShippingLabelAddressValidationResponse
        if hasDataEnvelope(in: response) {
            data = try decoder.decode(Envelope<ShippingLabelAddressValidationResponse>.self, from: response).data
        } else {
            data = try decoder.decode(ShippingLabelAddressValidationResponse.self, from: response)
        }

        return try data.result.get()
    }
}
