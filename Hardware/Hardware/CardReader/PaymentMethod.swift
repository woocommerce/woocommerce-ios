/// The type of the PaymentMethod.
public enum PaymentMethod {
    /// A card payment method.
    case card

    /// A card present payment method.
    /// If this is a card present payment method, this contains additional information.
    case presentCard(details: CardPresentTransactionDetails)

    /// An unknown type.
    case unknown
}
