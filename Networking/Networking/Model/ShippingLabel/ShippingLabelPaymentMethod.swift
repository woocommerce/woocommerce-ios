import Foundation

/// Represents a Shipping Label Payment Method.
///
public struct ShippingLabelPaymentMethod: Equatable, GeneratedFakeable {
    /// The remote ID for the payment method.
    public let paymentMethodID: Int64

    /// The billing name for the payment method.
    public let name: String

    /// The card type for the payment method.
    public let cardType: ShippingLabelPaymentCardType

    /// The last card digits for the payment method.
    public let cardDigits: String

    /// The expiry date for the payment method.
    public let expiry: Date?

    public init(paymentMethodID: Int64,
                name: String,
                cardType: ShippingLabelPaymentCardType,
                cardDigits: String,
                expiry: Date?) {
        self.paymentMethodID = paymentMethodID
        self.name = name
        self.cardType = cardType
        self.cardDigits = cardDigits
        self.expiry = expiry
    }
}

extension ShippingLabelPaymentMethod: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let paymentMethodID = try container.decode(Int64.self, forKey: .paymentMethodID)
        let name = try container.decode(String.self, forKey: .name)
        let cardType = try container.decode(ShippingLabelPaymentCardType.self, forKey: .cardType)
        let cardDigits = try container.decode(String.self, forKey: .cardDigits)
        let expiry = try container.decode(Date.self, forKey: .expiry)

        self.init(paymentMethodID: paymentMethodID, name: name, cardType: cardType, cardDigits: cardDigits, expiry: expiry)
    }
}

/// Defines all of the ShippingLabelPaymentMethod CodingKeys
///
private extension ShippingLabelPaymentMethod {
    private enum CodingKeys: String, CodingKey {
        case paymentMethodID = "payment_method_id"
        case name
        case cardType = "card_type"
        case cardDigits = "card_digits"
        case expiry
    }
}
