#if !targetEnvironment(macCatalyst)
import StripeTerminal

extension CardPresentTransactionDetails {

    /// Convenience initializer
    /// - Parameter reader: An instance of a StripeTerminal.CardPresentDetails
    init(details: StripeCardPresentDetails) {
        self.init(last4: details.last4,
                  expMonth: details.expMonth,
                  expYear: details.expYear,
                  cardholderName: details.cardholderName,
                  brand: CardBrand(brand: details.brand),
                  generatedCard: details.generatedCard,
                  receipt: Hardware.ReceiptDetails(receiptDetails: details.receipt),
                  emvAuthData: details.emvAuthData,
                  wallet: Wallet(type: details.wallet?.type),
                  network: details.network)
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
    var generatedCard: String? { get }
    var receipt: StripeTerminal.ReceiptDetails? { get }
    var emvAuthData: String? { get }
    var wallet: StripeTerminal.SCPWallet? { get }
    var network: NSNumber? { get }
}


extension StripeTerminal.CardPresentDetails: StripeCardPresentDetails {}
#endif
