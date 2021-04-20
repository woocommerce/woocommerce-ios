import Foundation

/// Mapper: WCPay Payment Intent
///
struct WCPayPaymentIntentMapper: Mapper {

    /// (Attempts) to convert a dictionary into an payment intent.
    ///
    func map(response: Data) throws -> WCPayPaymentIntent {
        let decoder = JSONDecoder()

        return try decoder.decode(WCPayPaymentIntentEnvelope.self, from: response).paymentIntent
    }
}

/// WCPayPaymentIntentEnvelope Disposable Entity
///
/// Endpoint returns the payment intent in the `data` key. This entity
/// allows us to parse it with JSONDecoder.
///
private struct WCPayPaymentIntentEnvelope: Decodable {
    let paymentIntent: WCPayPaymentIntent

    private enum CodingKeys: String, CodingKey {
        case paymentIntent = "data"
    }
}
