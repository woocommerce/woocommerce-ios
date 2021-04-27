import Networking
/// WCPayAction: Defines all of the Actions supported by the WCPayStore.
///
public enum WCPayAction: Action {
    /// Loads a WCPay account for a given site ID
    case loadAccount(siteID: Int64, onCompletion: (Result<WCPayAccount, Error>) -> Void)

    /// Captures a payment intent ID, associated to an order and site
    case captureOrderPayment(siteID: Int64,
                             orderID: Int64,
                             paymentIntentID: String,
                             completion: (Result<Void, Error>) -> Void)
}
