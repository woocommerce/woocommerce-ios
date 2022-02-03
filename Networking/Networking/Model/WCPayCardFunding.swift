import Foundation
import Codegen

/// Model containing information about how a card is funded
///
/// This is returned as part of the response from the `/payments/charges/<charge_id>` WCPay endpoint.
/// The endpoint returns a thin wrapper around the Stripe object, so
/// [these docs are relevant](https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-card-funding)
///
/// e.g. `credit`, `debit`, `prepaid`
///
public enum WCPayCardFunding: String, Codable, GeneratedCopiable, GeneratedFakeable, Equatable {
    case credit
    case debit
    case prepaid
    case unknown
}
