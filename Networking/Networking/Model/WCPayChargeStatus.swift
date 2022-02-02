import Foundation
import Codegen

/// Model containing information about the status of a WCPayCharge
///
/// This is returned as part of the response from the `/payments/charges/<charge_id>` WCPay endpoint.
/// The endpoint returns a thin wrapper around the Stripe object, so
/// [these docs are relevant](https://stripe.com/docs/api/charges/object#charge_object-status)
///
public enum WCPayChargeStatus: String, Decodable, GeneratedCopiable, GeneratedFakeable, Equatable {
    case succeeded
    case pending
    case failed
}
