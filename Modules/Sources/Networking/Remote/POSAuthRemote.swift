import Foundation

/// POS Auth: Remote Endpoints
///
public final class POSAuthRemote: Remote {

    /// Authenticates a POS operator via PIN.
    ///
    /// - Parameters:
    ///   - siteID: Site for which the operator is authenticating.
    ///   - pin: The operator's PIN code.
    ///   - registerID: The POS register identifier.
    /// - Returns: The authentication result containing user info and session credentials.
    ///
    public func authenticatePIN(siteID: Int64, pin: String, registerID: String) async throws -> POSPINAuthResult {
        let path = Constants.authPINPath
        let parameters: [String: Any] = [
            ParameterKeys.pin: pin,
            ParameterKeys.registerID: registerID
        ]
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .post,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        return try await enqueue(request)
    }

    /// Requests manager approval for a restricted POS action.
    ///
    /// - Parameters:
    ///   - siteID: Site for which the approval is requested.
    ///   - pin: The manager's PIN code.
    ///   - action: The capability being approved (e.g. "woocommerce_refund_orders").
    ///   - context: Additional context for the approval (e.g. ["order_id": 123]).
    /// - Returns: The approval result containing approval status and token.
    ///
    public func requestApproval(siteID: Int64,
                                pin: String,
                                action: String,
                                context: [String: Int64]) async throws -> POSApprovalResult {
        let path = Constants.authApprovePath
        var parameters: [String: Any] = [
            ParameterKeys.pin: pin,
            ParameterKeys.action: action
        ]
        if !context.isEmpty {
            parameters[ParameterKeys.context] = context
        }
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .post,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        return try await enqueue(request)
    }
}

private extension POSAuthRemote {
    enum ParameterKeys {
        static let pin = "pin"
        static let registerID = "register_id"
        static let action = "action"
        static let context = "context"
    }

    enum Constants {
        static let authPINPath = "pos/auth/pin"
        static let authApprovePath = "pos/auth/approve"
    }
}
