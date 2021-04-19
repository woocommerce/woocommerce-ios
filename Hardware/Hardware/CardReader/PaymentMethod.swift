/// The type of the PaymentMethod.
public enum PaymentMethod {
    /// A card payment method.
    case card

    /// A card present payment method.
    case presentCard(details: CardPresentDetails)

    /// An unknown type.
    case unknown
}
