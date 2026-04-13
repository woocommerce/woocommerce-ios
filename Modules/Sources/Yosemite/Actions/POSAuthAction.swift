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
                         idempotencyKey: String? = nil,
                         onCompletion: (Result<POSApprovalResult, Error>) -> Void)

    /// Fetches staff status including PIN setup state for all POS users.
    ///
    case fetchStaffStatus(siteID: Int64,
                          onCompletion: (Result<[POSStaffUser], Error>) -> Void)

    /// Sets or deletes a PIN for a POS staff user.
    ///
    case managePIN(siteID: Int64,
                   userID: Int64,
                   pin: String?,
                   action: String,
                   onCompletion: (Result<Bool, Error>) -> Void)
}
