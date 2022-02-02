import Foundation
import Codegen

// https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-type
public enum WCPayPaymentMethodType: String, Codable, GeneratedCopiable, GeneratedFakeable, Equatable {
    case card
    case cardPresent
    case unknown
}

internal extension WCPayPaymentMethodType {
    enum CodingKeys: String, CodingKey {
        case card
        case cardPresent = "card_present"
    }
}
