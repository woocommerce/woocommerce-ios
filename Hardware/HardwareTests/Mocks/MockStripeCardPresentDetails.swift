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
    public let generatedCard: String?
    public let receipt: StripeTerminal.ReceiptDetails?
    public let emvAuthData: String?
    public let wallet: StripeTerminal.SCPWallet?
    public let network: NSNumber?
}

extension MockStripeCardPresentDetails {
    static func mock() -> Self {
        MockStripeCardPresentDetails(last4: "1234",
                                     expMonth: 9,
                                     expYear: 2021,
                                     cardholderName: "Name",
                                     brand: .JCB,
                                     generatedCard: "generatedCard",
                                     receipt: nil,
                                     emvAuthData: "authdata",
                                     wallet: nil,
                                     network: NSNumber(integerLiteral: 1))
    }
}

extension MockStripeCardPresentDetails: StripeCardPresentDetails {}
