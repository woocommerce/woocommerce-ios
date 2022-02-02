import Foundation
import Codegen

// https://stripe.com/docs/api/charges/object#charge_object-status
public enum WCPayChargeStatus: String, Decodable, GeneratedCopiable, GeneratedFakeable, Equatable {
    case succeeded
    case pending
    case failed
}
