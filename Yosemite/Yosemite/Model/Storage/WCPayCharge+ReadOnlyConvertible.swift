import Foundation
import Storage
import Networking

// MARK: - Storage.WCPayCharge: ReadOnlyConvertible
//
extension Storage.WCPayCharge: ReadOnlyConvertible {

    /// Updates the `Storage.WCPayCharge` using the ReadOnly representation (`Networking.WCPayCharge`)
    ///
    /// - Parameter wcPayCharge: ReadOnly representation of WCPayCharge
    ///
    public func update(with wcPayCharge: Yosemite.WCPayCharge) {
        siteID = wcPayCharge.siteID
        chargeID = wcPayCharge.id
        amount = wcPayCharge.amount
        amountCaptured = wcPayCharge.amountCaptured
        amountRefunded = wcPayCharge.amountRefunded
        authorizationCode = wcPayCharge.authorizationCode
        captured = wcPayCharge.captured
        created = wcPayCharge.created
        currency = wcPayCharge.currency
        paid = wcPayCharge.paid
        paymentIntentID = wcPayCharge.paymentIntentID
        paymentMethodID = wcPayCharge.paymentMethodID
        paymentMethodType = wcPayCharge.paymentMethodDetails.paymentMethodType
        refunded = wcPayCharge.refunded
        status = wcPayCharge.status.rawValue
    }

    /// Returns a ReadOnly (`Networking.WCPayCharge`) version of the `Storage.WCPayCharge`
    ///
    public func toReadOnly() -> Yosemite.WCPayCharge {
        let paymentMethodDetails = WCPayPaymentMethodDetails(type: paymentMethodType,
                                                             cardDetails: cardDetails?.toReadOnly(),
                                                             cardPresentDetails: cardPresentDetails?.toReadOnly())
        return WCPayCharge(siteID: siteID,
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
                           status: WCPayChargeStatus(rawValue: status) ?? .succeeded)
    }
}

private extension WCPayPaymentMethodDetails {
    var paymentMethodType: String {
        switch self {
        case .unknown:
            return "unknown"
        case .card(_):
            return "card"
        case .cardPresent(_):
            return "cardPresent"
        }
    }

    init(type: String, cardDetails: WCPayCardPaymentDetails?, cardPresentDetails: WCPayCardPresentPaymentDetails?) {
        switch (type, cardDetails, cardPresentDetails) {
        case ("unknown", _, _):
            self = .unknown
        case ("card", .some(let cardDetails), _):
            self = .card(details: cardDetails)
        case ("cardPresent", _, .some(let cardPresentDetails)):
            self = .cardPresent(details: cardPresentDetails)
        default:
            self = .unknown
        }
    }
}
