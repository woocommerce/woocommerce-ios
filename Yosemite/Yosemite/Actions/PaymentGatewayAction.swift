import Foundation

/// Defines all of the `actions` supported by the `PaymentGatewayStore`.
///
public enum PaymentGatewayAction: Action {
    /// Retrieves and stores all payment gateways for the provided `siteID`
    ///
    case synchronizePaymentGateways(siteID: Int64, onCompletion: (Result<Void, Error>) -> Void)
}
