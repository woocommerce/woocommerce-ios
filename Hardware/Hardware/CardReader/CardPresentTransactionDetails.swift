/// An object representing details from a transaction using a card_present payment method.
public struct CardPresentTransactionDetails: Codable, Equatable {
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

    public init(last4: String,
                expMonth: Int,
                expYear: Int,
                cardholderName: String?,
                brand: CardBrand,
                fingerprint: String,
                generatedCard: String?,
                receipt: ReceiptDetails?,
                emvAuthData: String?) {
        self.last4 = last4
        self.expMonth = expMonth
        self.expYear = expYear
        self.cardholderName = cardholderName
        self.brand = brand
        self.fingerprint = fingerprint
        self.generatedCard = generatedCard
        self.receipt = receipt
        self.emvAuthData = emvAuthData
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let last4 = try container.decode(String.self, forKey: .last4)
        let expMonth = try container.decode(Int.self, forKey: .expMonth)
        let expYear = try container.decode(Int.self, forKey: .expYear)
        let cardholderName = try container.decodeIfPresent(String.self, forKey: .cardholderName)

        #warning("Don't merge this or everything will be Interac on our IPP receipts!")
        let brand = CardBrand.interac

        let fingerprint = try container.decode(String.self, forKey: .fingerprint)
        let generatedCard = try container.decodeIfPresent(String.self, forKey: .generatedCard)
        let receipt = try container.decodeIfPresent(ReceiptDetails.self, forKey: .receipt)
        let emvAuthData = try container.decodeIfPresent(String.self, forKey: .emvAuthData)
        self.init(last4: last4,
                  expMonth: expMonth,
                  expYear: expYear,
                  cardholderName: cardholderName,
                  brand: brand,
                  fingerprint: fingerprint,
                  generatedCard: generatedCard,
                  receipt: receipt,
                  emvAuthData: emvAuthData)
    }
}

extension CardPresentTransactionDetails {
    enum CodingKeys: String, CodingKey {
        case last4 = "last_4"
        case expMonth = "exp_month"
        case expYear = "exp_year"
        case cardholderName = "cardholder_name"
        case brand = "brand"
        case fingerprint = "fingerprint"
        case generatedCard = "generated_card"
        case receipt = "receipt"
        case emvAuthData = "emv_auth_data"
    }
}
