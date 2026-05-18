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
    case cartesBancaires = "cartes_bancaires"
    case diners
    case discover
    case eftposAu = "eftpos_au"
    case interac
    case jcb
    case mastercard
    case unionpay
    case visa
    case unknown

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = WCPayCardBrand(rawValue: rawValue) ?? .unknown
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
