import Foundation
import Codegen

// https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-card_present
public struct WCPayCardPresentPaymentDetails: Codable, GeneratedCopiable, GeneratedFakeable, Equatable {
    let brand: WCPayCardBrand
    let last4: String
    let funding: WCPayAccountType
    let receipt: WCPayCardPresentReceiptDetails

    public init(brand: WCPayCardBrand,
                last4: String,
                funding: WCPayAccountType,
                receipt: WCPayCardPresentReceiptDetails) {
        self.brand = brand
        self.last4 = last4
        self.funding = funding
        self.receipt = receipt
    }
}
