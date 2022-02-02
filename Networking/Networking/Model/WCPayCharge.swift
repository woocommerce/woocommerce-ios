import Foundation
import Codegen

/// Model for the `/payments/charges/<charge_id>` WCPay endpoint.
///
/// The endpoint returns a thin wrapper around the Stripe object, so these docs are relevant: https://stripe.com/docs/api/charges/object
///
public struct WCPayCharge: Decodable, GeneratedCopiable, GeneratedFakeable, Equatable {
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

// MARK: - Decoding Errors
enum WCPayChargeDecodingError: Error {
    case missingSiteID
}
