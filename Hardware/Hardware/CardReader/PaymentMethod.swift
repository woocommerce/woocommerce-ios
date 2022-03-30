/// The type of the PaymentMethod.
public enum PaymentMethod {
    /// A card payment method.
    case card

    /// A card present payment method.
    /// If this is a card present payment method, this contains additional information.
    case cardPresent(details: CardPresentTransactionDetails)

    /// An Interac present payment method.
    /// If this is a card present payment method, this contains additional information.
    case interacPresent(details: CardPresentTransactionDetails)

    /// An unknown type.
    case unknown
}

extension PaymentMethod {
    /// Returns the associated card present transaction details if the payment method was `cardPresent` or `interacPresent`.
    ///
    public var cardPresentDetails: CardPresentTransactionDetails? {
        switch self {
        case .cardPresent(details: let details):
            return details
        case .interacPresent(details: let details):
            return details
        default:
            return nil
        }
    }
}
