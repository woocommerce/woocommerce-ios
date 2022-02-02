import Foundation
import Codegen

// https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-card-brand
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
