#if os(iOS)

import Foundation
import Codegen

/// Model containing information about a WCPay Charge.
///
/// This is returned as the response from the `/payments/charges/<charge_id>` WCPay endpoint.
/// The endpoint returns a thin wrapper around the Stripe object, so
/// [these docs are relevant](https://stripe.com/docs/api/charges/object)
///
public struct WCPayCharge: Decodable, GeneratedCopiable, GeneratedFakeable, Equatable {
    /// The siteID of the site that the charge relates to
    public let siteID: Int64

    /// The chargeID – matches Stripe's charge ID, e.g. `ch_3KMVap2EdyGr1FMV1uKJEWtg`
    public let id: String

    /// The amount charged, in the smallest units of the relevant currency
    public let amount: Int64

    /// The amount captured, i.e. taken from the card, in the smallest units of the relevant currency
    public let amountCaptured: Int64

    /// The amount refunded, in the smallest units of the relevant currency. 0 if no refunds.
    public let amountRefunded: Int64

    /// The authorization code for the charge. This is not part of the Stripe model, but a WCPay-added field.
    public let authorizationCode: String?

    /// Whether the charge has been captured yet
    public let captured: Bool

    /// The date the charge was created
    public let created: Date // = 1643280767

    /// The currency for the charge, as a 3-letter code e.g. `usd`
    public let currency: String

    /// Whether the charge succeeded
    public let paid: Bool

    /// The ID for the payment intent associated with this charge, e.g. `pi_3KMVap2EdyGr1FMV16atNgK9`
    public let paymentIntentID: String?

    /// The ID for the payment method for this charge, e.g. `pm_1KMVas2EdyGr1FMVnleuPovE`
    public let paymentMethodID: String

    /// The details of the payment method used, including the type of payment, and associated details about that type.
    public let paymentMethodDetails: WCPayPaymentMethodDetails

    /// Whether the charge has been *fully* refunded or not. Will be `false` for partial refunds.
    public let refunded: Bool

    /// The charge's success status
    public let status: WCPayChargeStatus

    public init(siteID: Int64,
                id: String,
                amount: Int64,
                amountCaptured: Int64,
                amountRefunded: Int64,
                authorizationCode: String?,
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
        let authorizationCode = try container.decodeIfPresent(String.self, forKey: .authorizationCode)
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

#endif
