@testable import Hardware
import StripeTerminal
// This structs emulates the properties of SCPCardPresentDetails
// We can not mock SCPCardPresentDetails directly, because its initializers
// are annotated as NS_UNAVAILABLE
struct MockStripeCardPresentDetails {
    public let last4: String
    public let expMonth: Int
    public let expYear: Int
    public let cardholderName: String?
    public let brand: StripeTerminal.CardBrand
    public let fingerprint: String
    public let generatedCard: String?
    public let receipt: StripeTerminal.ReceiptDetails?
    public let emvAuthData: String?
}

extension MockStripeCardPresentDetails: StripeCardPresentDetails {}

extension MockStripeCardPresentDetails {
    static func mock() -> Self {
        MockStripeCardPresentDetails(last4: "1234",
                                     expMonth: 9,
                                     expYear: 2021,
                                     cardholderName: "Name",
                                     brand: .JCB,
                                     fingerprint: "fingerprint",
                                     generatedCard: "generatedCard",
                                     receipt: nil,
                                     emvAuthData: "authdata")
    }
}
