import Foundation

/// Defines all of the `actions` supported by the `PaymentGatewayStore`.
///
public enum PaymentGatewayAction: Action {
    /// Retrieves and stores all payment gateways for the provided `siteID`
    ///
    case synchronizePaymentGateways(siteID: Int64, onCompletion: (Result<Void, Error>) -> Void)

    /// Updates a Payment Gateway for a site given its ID and returns the updated Payment Gateway if the request succeeds.
    ///
    /// - `paymentGateway`: the Payment Gateway to be updated.
    /// - `onCompletion`: invoked when the update finishes.
    ///
    case updatePaymentGateway(_ paymentGateway: PaymentGateway,
                              onCompletion: (Result<PaymentGateway, Error>) -> Void)
}
