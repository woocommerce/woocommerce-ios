import Codegen
import Foundation

/// Info for payments when creating Blaze campaigns.
public struct BlazePaymentInfo: Decodable, Equatable, GeneratedFakeable, GeneratedCopiable {

    /// List of saved payment methods for Blaze campaign creation
    public let paymentMethods: [BlazePaymentMethod]

    public init(paymentMethods: [BlazePaymentMethod]) {
        self.paymentMethods = paymentMethods
    }
}

/// Details for a payment method to be used for Blaze campaign creation.
public struct BlazePaymentMethod: Decodable, Equatable, GeneratedFakeable, GeneratedCopiable, Identifiable {

    /// ID of the payment method
    public let id: String

    /// Raw value of the payment method type
    public let rawType: String

    /// Name of the payment method
    public let name: String

    /// Detailed info about the payment method
    public let info: Info

    /// Decoded value of the payment method type
    public var type: PaymentMethodType {
        PaymentMethodType(rawValue: rawType) ?? .unknown
    }

    public init(id: String,
                rawType: String,
                name: String,
                info: BlazePaymentMethod.Info) {
        self.id = id
        self.rawType = rawType
        self.name = name
        self.info = info
    }

    public enum PaymentMethodType: String {
        case creditCard = "credit_card"
        case unknown
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case rawType = "type"
        case name
        case info
    }
}

public extension BlazePaymentMethod {

    /// Detailed info for a payment method to be used for Blaze campaign creation.
    struct Info: Decodable, Equatable, GeneratedFakeable, GeneratedCopiable {

        /// Last 4 digits of the card
        public let lastDigits: String

        /// Expiring info of the card
        public let expiring: ExpiringInfo

        /// Raw value of the card type. E.g.: Visa, Mastercard, etc.
        public let type: String

        /// Nickname of the card if available
        public let nickname: String?

        /// Name of the card holder
        public let cardholderName: String

        public init(lastDigits: String,
                    expiring: ExpiringInfo,
                    type: String,
                    nickname: String?,
                    cardholderName: String) {
            self.lastDigits = lastDigits
            self.expiring = expiring
            self.type = type
            self.nickname = nickname
            self.cardholderName = cardholderName
        }
    }

    /// Expiring info of a payment method to be used for Blaze campaign creation
    struct ExpiringInfo: Decodable, Equatable, GeneratedFakeable, GeneratedCopiable {

        /// Expiring year of the payment method
        public let year: Int

        /// Expiring month of the payment method
        public let month: Int

        public init(year: Int, month: Int) {
            self.year = year
            self.month = month
        }
    }
}
