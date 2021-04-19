/// Details about a PaymentMethod at a specific time. ex: at time of transaction for a Charge.
public struct PaymentMethodDetails {
    /// The type of the PaymentMethod.
    /// The corresponding, similarly named property contains additional information specific to the PaymentMethod type.
    /// e.g. if the type is .present, the cardPresent property is also populated.
    public let type: PaymentMethodType

    /// If this is a card present payment method (ie self.type == .present), this contains additional information.
    public let cardPresent: CardPresentDetails?
}
