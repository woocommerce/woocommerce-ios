import StripeTerminal

protocol ToStripe {
    associatedtype StripeModelObject
    func toStripe() -> StripeModelObject?
}

extension CardReader: ToStripe {
    func toStripe() -> Reader? {
        stripeReader as? Reader
    }
}
