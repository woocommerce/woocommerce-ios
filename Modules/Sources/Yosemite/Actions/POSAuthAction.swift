import Foundation
import Networking

/// POSAuthAction: Defines all of the Actions supported by the POSAuthStore.
///
public enum POSAuthAction: Action {

    /// Authenticates a POS operator via PIN against the backend REST API.
    ///
    case authenticatePIN(siteID: Int64,
                         pin: String,
                         registerID: String,
                         onCompletion: (Result<POSPINAuthResult, Error>) -> Void)

    /// Requests manager approval for a restricted POS action.
    ///
    case requestApproval(siteID: Int64,
                         pin: String,
                         action: String,
                         context: [String: Int64],
                         onCompletion: (Result<POSApprovalResult, Error>) -> Void)
}
