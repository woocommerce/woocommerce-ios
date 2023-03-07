import Foundation
import Codegen

/// Model for a WCPay payment method type
///
/// This is returned as part of the response from the `/payments/charges/<charge_id>` WCPay endpoint.
/// The endpoint returns a thin wrapper around the Stripe object, so
/// [these docs are relevant](https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-type)
///
public enum WCPayPaymentMethodType: String, Codable, GeneratedCopiable, GeneratedFakeable, Equatable {
    case card
    case cardPresent = "card_present"
    case interacPresent = "interac_present"
    case unknown
}
