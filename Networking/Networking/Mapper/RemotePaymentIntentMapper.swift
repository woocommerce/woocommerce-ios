/// Mapper: WCPay Payment Intent
///
struct RemotePaymentIntentMapper: Mapper {

    /// (Attempts) to convert a dictionary into an payment intent.
    ///
    func map(response: Data) throws -> RemotePaymentIntent {
        return try extract(from: response, using: JSONDecoder())
    }
}
