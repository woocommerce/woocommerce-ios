import Foundation
import Networking

/// Defines all of the `actions` supported by the `PaymentGatewayAccountStore`.
///
public enum PaymentGatewayAccountAction: Action {
    /// Retrieves and stores payment gateway accounts for the provided `siteID`
    ///
    case loadAccounts(siteID: Int64, onCompletion: (Result<[PaymentGatewayAccount], Error>) -> Void)
}
