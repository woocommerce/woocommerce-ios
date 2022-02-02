import Foundation
import Codegen

/// Model for card brands as returned from WCPay.
///
/// This is returned as part of the response from the `/payments/charges/<charge_id>` WCPay endpoint.
/// The endpoint returns a thin wrapper around the Stripe object, so
/// [these docs are relevant](https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-card-brand)
///
public enum WCPayCardBrand: String, Codable, GeneratedCopiable, GeneratedFakeable, Equatable {
    case amex
    case diners
    case discover
    case jcb
    case mastercard
    case unionpay
    case visa
    case unknown
}
