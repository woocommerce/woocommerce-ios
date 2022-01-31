import Foundation
import Codegen

/// Model for the `/payments/charges/<charge_id>` WCPay endpoint.
/// The API returns a thin wrapper around the Stripe object, so these docs are relevant: https://stripe.com/docs/api/charges/object

public struct WCPayCharge: Decodable, GeneratedCopiable, GeneratedFakeable {
    public let siteID: Int64
    public let id: String
    public let amount: Int64
    public let amountCaptured: Int64
    public let amountRefunded: Int64
    public let authorizationCode: String
    public let captured: Bool
    public let created: Date // = 1643280767
    public let currency: String // = "usd",
    public let paid: Bool
    public let paymentIntentID: String?
    public let paymentMethodID: String
    public let paymentMethodDetails: WCPayPaymentMethodDetails
    public let refunded: Bool
    public let status: WCPayChargeStatus

    public init(siteID: Int64,
                id: String,
                amount: Int64,
                amountCaptured: Int64,
                amountRefunded: Int64,
                authorizationCode: String,
                captured: Bool,
                created: Date,
                currency: String,
                paid: Bool,
                paymentIntentID: String?,
                paymentMethodID: String,
                paymentMethodDetails: WCPayPaymentMethodDetails,
                refunded: Bool,
                status: WCPayChargeStatus) {
        self.siteID = siteID
        self.id = id
        self.amount = amount
        self.amountCaptured = amountCaptured
        self.amountRefunded = amountRefunded
        self.authorizationCode = authorizationCode
        self.captured = captured
        self.created = created
        self.currency = currency
        self.paid = paid
        self.paymentIntentID = paymentIntentID
        self.paymentMethodID = paymentMethodID
        self.paymentMethodDetails = paymentMethodDetails
        self.refunded = refunded
        self.status = status
    }

    /// The public initializer for WCPayCharge.
        ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw WCPayChargeDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let chargeID = try container.decode(String.self, forKey: .chargeID)
        let amount = try container.decode(Int64.self, forKey: .amount)
        let amountCaptured = try container.decode(Int64.self, forKey: .amountCaptured)
        let amountRefunded = try container.decode(Int64.self, forKey: .amountRefunded)
        let authorizationCode = try container.decode(String.self, forKey: .authorizationCode)
        let captured = try container.decode(Bool.self, forKey: .captured)
        let created = try container.decode(Date.self, forKey: .created)
        let currency = try container.decode(String.self, forKey: .currency)
        let paid = try container.decode(Bool.self, forKey: .paid)
        let paymentIntentID = try container.decodeIfPresent(String.self, forKey: .paymentIntentID)
        let paymentMethodID = try container.decode(String.self, forKey: .paymentMethodID)
        let paymentMethodDetails = try container.decode(WCPayPaymentMethodDetails.self, forKey: .paymentMethodDetails)
        let refunded = try container.decode(Bool.self, forKey: .refunded)
        let status = try container.decode(WCPayChargeStatus.self, forKey: .status)

        self.init(siteID: siteID,
                  id: chargeID,
                  amount: amount,
                  amountCaptured: amountCaptured,
                  amountRefunded: amountRefunded,
                  authorizationCode: authorizationCode,
                  captured: captured,
                  created: created,
                  currency: currency,
                  paid: paid,
                  paymentIntentID: paymentIntentID,
                  paymentMethodID: paymentMethodID,
                  paymentMethodDetails: paymentMethodDetails,
                  refunded: refunded,
                  status: status)
    }
}

// MARK: WCPayChargeStatus
public enum WCPayChargeStatus: String, Decodable {
    case succeeded
    case pending
    case failed
    case unknown
}

extension WCPayChargeStatus: RawRepresentable {
    // Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.succeeded:
            self = .succeeded
        case Keys.pending:
            self = .pending
        case Keys.failed:
            self = .failed
        default:
            self = .unknown
        }
    }

    /// Returns the current Enum Case's Raw Value
    ///
    public var rawValue: String {
        switch self {
        case .succeeded: return Keys.succeeded
        case .pending: return Keys.pending
        case .failed: return Keys.failed
        case .unknown: return Keys.unknown
        }
    }
}

/// Enum containing the 'Known' WCPayChargeStatus Keys
///
private extension WCPayChargeStatus {
    enum Keys {
        static let succeeded = "succeeded"
        static let pending = "pending"
        static let failed = "failed"
        static let unknown = "unknown"
    }
}

// MARK: WCPayPaymentMethodDetails
public enum WCPayPaymentMethodDetails: Decodable {
    case card(details: CardPaymentDetails) //type = card
    case cardPresent(details: CardPresentPaymentDetails) //type = card_present
    case unknown

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let type = try? container.decode(PaymentMethodType.self, forKey: .type) else {
            self = .unknown
            return
        }

        switch type {
        case .card:
            guard let cardDetails = try? container.decode(CardPaymentDetails.self, forKey: .card) else {
                throw WCPayPaymentMethodDetailsDecodingError.noDetailsPresentForPaymentType
            }
            self = .card(details: cardDetails)
        case .cardPresent:
            guard let cardPresentDetails = try? container.decode(CardPresentPaymentDetails.self, forKey: .cardPresent) else {
                throw WCPayPaymentMethodDetailsDecodingError.noDetailsPresentForPaymentType
            }
            self = .cardPresent(details: cardPresentDetails)
        case .unknown:
            self = .unknown
        }
    }

    // https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-type
    public enum PaymentMethodType: String, Decodable {
        case card
        case cardPresent
        case unknown
    }

    // https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-card
    public struct CardPaymentDetails: Decodable, GeneratedCopiable, GeneratedFakeable {
        let brand: CardBrand
        let last4: String
        let funding: AccountType

        public init(brand: CardBrand,
                    last4: String,
                    funding: AccountType) {
            self.brand = brand
            self.last4 = last4
            self.funding = funding
        }
    }

    public enum CardBrand: String, Decodable {
        case amex
        case diners
        case discover
        case jcb
        case mastercard
        case unionpay
        case visa
        case unknown
    }

    public enum AccountType: String, Decodable {
        case credit
        case debit
        case prepaid
        case unknown
    }

    // https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-card_present
    public struct CardPresentPaymentDetails: Decodable, GeneratedCopiable, GeneratedFakeable {
        let brand: CardBrand
        let last4: String
        let funding: AccountType
        let receipt: CardPresentReceiptDetails

        public init(brand: CardBrand,
                    last4: String,
                    funding: AccountType,
                    receipt: CardPresentReceiptDetails) {
            self.brand = brand
            self.last4 = last4
            self.funding = funding
            self.receipt = receipt
        }
    }

    // https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-card_present-receipt
    public struct CardPresentReceiptDetails: Decodable, GeneratedCopiable, GeneratedFakeable {
        let accountType: AccountType
        let applicationPreferredName: String
        let dedicatedFileName: String

        public init(accountType: AccountType,
                    applicationPreferredName: String,
                    dedicatedFileName: String) {
            self.accountType = accountType
            self.applicationPreferredName = applicationPreferredName
            self.dedicatedFileName = dedicatedFileName
        }
    }
}


// MARK: CodingKeys
internal extension WCPayCharge {
    enum CodingKeys: String, CodingKey {
        case chargeID = "id"
        case amount
        case amountCaptured = "amount_captured"
        case amountRefunded = "amount_refunded"
        case authorizationCode = "authorization_code"
        case captured
        case created
        case currency
        case paid
        case paymentIntentID = "payment_intent"
        case paymentMethodID = "payment_method"
        case paymentMethodDetails = "payment_method_details"
        case refunded
        case status
    }
}

internal extension WCPayPaymentMethodDetails {
    enum CodingKeys: String, CodingKey {
        case type
        case card
        case cardPresent = "card_present"
    }
}

internal extension WCPayPaymentMethodDetails.PaymentMethodType {
    enum CodingKeys: String, CodingKey {
        case card
        case cardPresent = "card_present"
    }
}

internal extension WCPayPaymentMethodDetails.CardPaymentDetails {
    enum CodingKeys: String, CodingKey {
        case brand
        case last4
        case funding
    }
}

internal extension WCPayPaymentMethodDetails.CardPresentPaymentDetails {
    enum CodingKeys: String, CodingKey {
        case brand
        case last4
        case funding
        case receipt
    }
}

internal extension WCPayPaymentMethodDetails.CardPresentReceiptDetails {
    enum CodingKeys: String, CodingKey {
        case accountType = "account_type"
        case applicationPreferredName = "application_preferred_name"
        case dedicatedFileName = "dedicated_file_name"
    }
}

// MARK: - Decoding Errors
//
enum WCPayChargeDecodingError: Error {
    case missingSiteID
}

enum WCPayPaymentMethodDetailsDecodingError: Error {
    case noDetailsPresentForPaymentType
}
