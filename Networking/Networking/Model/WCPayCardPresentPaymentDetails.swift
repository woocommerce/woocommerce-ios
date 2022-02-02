import Foundation
import Codegen

/// Model containing information about a card present payment.
///
/// This is returned as part of the response from the `/payments/charges/<charge_id>` WCPay endpoint.
/// The endpoint returns a thin wrapper around the Stripe object, so
/// [these docs are relevant](https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-card_present)
///
public struct WCPayCardPresentPaymentDetails: Codable, GeneratedCopiable, GeneratedFakeable, Equatable {
    /// The brand of the card, e.g. `amex`, `mastercard`, `visa`, etc
    let brand: WCPayCardBrand
    
    /// The last 4 digits of the card number
    let last4: String

    /// The way the card is funded, e.g. `credit`, `debit`, `prepaid`
    let funding: WCPayCardFunding

    /// Required receipt details (some mandatory for EMV receipts)
    let receipt: WCPayCardPresentReceiptDetails

    public init(brand: WCPayCardBrand,
                last4: String,
                funding: WCPayCardFunding,
                receipt: WCPayCardPresentReceiptDetails) {
        self.brand = brand
        self.last4 = last4
        self.funding = funding
        self.receipt = receipt
    }
}
