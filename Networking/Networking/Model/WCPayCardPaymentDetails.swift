import Foundation
import Codegen

/// Model containing information about a WCPay card payment.
///
/// This is returned as part of the response from the `/payments/charges/<charge_id>` WCPay endpoint.
/// The endpoint returns a thin wrapper around the Stripe object, so
/// [these docs are relevant](https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-card)
///
public struct WCPayCardPaymentDetails: Codable, GeneratedCopiable, GeneratedFakeable, Equatable {
    /// The brand of the card used to pay, e.g. `amex`, `mastercard`, `visa`
    public let brand: WCPayCardBrand

    /// The last 4 digits of the card number
    public let last4: String

    /// The way the card is funded, e.g. `credit`, `debit`, `prepaid`
    public let funding: WCPayCardFunding

    public init(brand: WCPayCardBrand,
                last4: String,
                funding: WCPayCardFunding) {
        self.brand = brand
        self.last4 = last4
        self.funding = funding
    }
}
