import Foundation
import Networking

/// Defines all of the `actions` supported by the `PaymentGatewayAccountStore`.
///
public enum PaymentGatewayAccountAction: Action {
    /// Retrieves and stores payment gateway account(s) for the provided `siteID`
    ///
    case loadAccounts(siteID: Int64, onCompletion: (Result<Void, Error>) -> Void)

    /// Get a Stripe Customer for an order.
    ///
    case fetchOrderCustomer(siteID: Int64, orderID: Int64, onCompletion: (Result<WCPayCustomer, Error>) -> Void)

    /// Captures a payment intent ID, associated to an order and site
    case captureOrderPayment(siteID: Int64,
                             orderID: Int64,
                             paymentIntentID: String,
                             completion: (Result<Void, Error>) -> Void)
}
