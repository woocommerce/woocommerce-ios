/// Mapper for a `PaymentGateway` JSON object
///
struct PaymentGatewayMapper: Mapper {

    /// Site Identifier associated to the payment gateway that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't
    /// return the siteID for the payment gateway endpoint
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into `PaymentGateway`
    ///
    func map(response: Data) throws -> PaymentGateway {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID,
        ]
        if hasDataEnvelope(in: response) {
            return try decoder.decode(Envelope<PaymentGateway>.self, from: response).data
        } else {
            return try decoder.decode(PaymentGateway.self, from: response)
        }
    }
}
