import Foundation
import Codegen

/// Model containing the details of a payment method from WCPay.
///
/// This is returned as part of the response from the `/payments/charges/<charge_id>` WCPay endpoint.
/// The endpoint returns a thin wrapper around the Stripe object, so
/// [these docs are relevant](https://stripe.com/docs/api/charges/object#charge_object-payment_method_details)
///
public enum WCPayPaymentMethodDetails: Decodable, GeneratedCopiable, GeneratedFakeable, Equatable {
    case unknown

    /// A card payment, with `details`. This represents a payment made online, rather than in-person
    case card(details: WCPayCardPaymentDetails)

    /// A card present payment, with `details`. This represents an In-Person Payment.
    case cardPresent(details: WCPayCardPresentPaymentDetails)

    /// An interac present payment, with `details`. This represents an In-Person Payment, and is specific to some Canadian payments.
    case interacPresent(details: WCPayCardPresentPaymentDetails)

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let type = try? container.decode(WCPayPaymentMethodType.self, forKey: .type) else {
            self = .unknown
            return
        }

        switch type {
        case .card:
            guard let cardDetails = try? container.decode(WCPayCardPaymentDetails.self, forKey: .card) else {
                throw WCPayPaymentMethodDetailsDecodingError.noDetailsPresentForPaymentType
            }
            self = .card(details: cardDetails)
        case .cardPresent:
            guard let cardPresentDetails = try? container.decode(WCPayCardPresentPaymentDetails.self, forKey: .cardPresent) else {
                throw WCPayPaymentMethodDetailsDecodingError.noDetailsPresentForPaymentType
            }
            self = .cardPresent(details: cardPresentDetails)
        case .interacPresent:
            guard let interacPresentDetails = try? container.decode(WCPayCardPresentPaymentDetails.self, forKey: .interacPresent) else {
                throw WCPayPaymentMethodDetailsDecodingError.noDetailsPresentForPaymentType
            }
            self = .interacPresent(details: interacPresentDetails)
        case .unknown:
            self = .unknown
        }
    }
}

internal extension WCPayPaymentMethodDetails {
    enum CodingKeys: String, CodingKey {
        case type
        case card
        case cardPresent = "card_present"
        case interacPresent = "interac_present"
    }
}

enum WCPayPaymentMethodDetailsDecodingError: Error {
    case noDetailsPresentForPaymentType
}
