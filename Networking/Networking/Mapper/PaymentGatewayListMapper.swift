/// Mapper for an array of `PaymentGateway` JSON objects
///
struct PaymentGatewayListMapper: Mapper {

    /// Site Identifier associated to the payment gateways that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't
    /// return the siteID for the payment gateway endpoint
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into `[PaymentGateway]`
    ///
    func map(response: Data) throws -> [PaymentGateway] {
        try extract(from: response, siteID: siteID)
    }
}
