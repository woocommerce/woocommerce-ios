import StripeTerminal

extension CardPresentTransactionDetails {

    /// Convenience initializer
    /// - Parameter reader: An instance of a StripeTerminal.CardPresentDetails
    init(details: StripeCardPresentDetails) {
        self.last4 = details.last4
        self.expMonth = details.expMonth
        self.expYear = details.expYear
        self.cardholderName = details.cardholderName
        self.brand = CardBrand(brand: details.brand)
        self.fingerprint = details.fingerprint
        self.generatedCard = details.generatedCard
        self.receipt = Hardware.ReceiptDetails(receiptDetails: details.receipt)
        self.emvAuthData = details.emvAuthData
    }
}


/// The initializers of StripeTerminal.CardPresentDetails are annotated as NS_UNAVAILABLE
/// So we can not create instances of that class in our tests.
/// A workaround is declaring this protocol, which matches the parts of
/// SCPReader that we are interested in, make Reader implement it,
/// and initialize Harware.CardReader with a type conforming to it.
protocol StripeCardPresentDetails {
    var last4: String { get }
    var expMonth: Int { get }
    var expYear: Int { get }
    var cardholderName: String? { get }
    var brand: StripeTerminal.CardBrand { get }
    var fingerprint: String { get }
    var generatedCard: String? { get }
    var receipt: StripeTerminal.ReceiptDetails? { get }
    var emvAuthData: String? { get }
}


extension StripeTerminal.CardPresentDetails: StripeCardPresentDetails {}
