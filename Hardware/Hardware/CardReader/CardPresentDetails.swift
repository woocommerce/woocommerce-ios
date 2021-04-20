/// An object representing details from a transaction using a card_present payment method.
public struct CardPresentDetails {
    /// The last 4 digits of the card.
    public let last4: String

    /// The card’s expiration month. 1-indexed (i.e. 1 == January)
    public let expMonth: Int

    /// The card’s expiration year. Four digits.
    public let expYear: Int

    /// The cardholder name as read from the card, in ISO 7813 format.
    /// May include alphanumeric characters, special characters and first/last name separator (/).
    public let cardholderName: String?

    /// The issuing brand of the card.
    public let brand: CardBrand

    /// A string uniquely identifying this card number.
    public let fingerprint: String

    /// ID of a card PaymentMethod that may be attached to a Customer for future transactions.
    /// Only present if it was possible to generate a card PaymentMethod.
    public let generatedCard: String?

    /// Receipt information for the card present transaction. Only present for EMV transactions.
    public let receipt: ReceiptDetails?

    /// (Only applicable to EMV payments) The authorization data from the card issuer.
    public let emvAuthData: String?
}
