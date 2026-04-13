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
    /// - Throws: `POSAuthError` when the backend returns a known POS error code.
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
        do {
            return try await enqueue(request, mapper: POSPINAuthResultMapper())
        } catch let posError as POSAuthError {
            throw posError
        } catch {
            throw POSAuthError.from(error)
        }
    }

    /// Requests manager approval for a restricted POS action.
    ///
    /// - Parameters:
    ///   - siteID: Site for which the approval is requested.
    ///   - pin: The manager's PIN code.
    ///   - action: The capability being approved (e.g. "woocommerce_refund_orders").
    ///   - context: Additional context for the approval (e.g. ["order_id": 123]).
    /// - Returns: The approval result containing approval status and token.
    /// - Throws: `POSAuthError` when the backend returns a known POS error code.
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
        do {
            return try await enqueue(request, mapper: POSApprovalResultMapper())
        } catch let posError as POSAuthError {
            throw posError
        } catch {
            throw POSAuthError.from(error)
        }
    }

    /// Fetches staff status including PIN setup state for all POS users.
    ///
    /// - Parameter siteID: Site for which to fetch staff status.
    /// - Returns: A list of staff users with their PIN configuration status.
    /// - Throws: `POSAuthError` when the backend returns a known POS error code.
    ///
    public func fetchStaffStatus(siteID: Int64) async throws -> [POSStaffUser] {
        let path = Constants.pinStatusPath
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     availableAsRESTRequest: true)
        do {
            return try await enqueue(request, mapper: POSStaffStatusMapper())
        } catch let posError as POSAuthError {
            throw posError
        } catch {
            throw POSAuthError.from(error)
        }
    }

    /// Sets or deletes a PIN for a POS staff user.
    ///
    /// - Parameters:
    ///   - siteID: Site for which to manage the PIN.
    ///   - userID: The user whose PIN is being managed.
    ///   - pin: The new PIN to set, or `nil` when deleting.
    ///   - action: The management action to perform ("set" or "delete").
    /// - Returns: `true` if the operation succeeded.
    /// - Throws: `POSAuthError` when the backend returns a known POS error code.
    ///
    public func managePIN(siteID: Int64,
                          userID: Int64,
                          pin: String?,
                          action: String) async throws -> Bool {
        let path = Constants.pinManagePath
        var parameters: [String: Any] = [
            ParameterKeys.userID: userID,
            ParameterKeys.action: action
        ]
        if let pin {
            parameters[ParameterKeys.pin] = pin
        }
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .post,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        do {
            let result: POSPINManageResult = try await enqueue(request)
            return result.success
        } catch {
            throw POSAuthError.from(error)
        }
    }
}

private extension POSAuthRemote {
    enum ParameterKeys {
        static let pin = "pin"
        static let registerID = "register_id"
        static let action = "action"
        static let context = "context"
        static let userID = "user_id"
    }

    enum Constants {
        static let authPINPath = "pos/auth/pin"
        static let authApprovePath = "pos/auth/approve"
        static let pinStatusPath = "pos/auth/pin/status"
        static let pinManagePath = "pos/auth/pin/manage"
    }
}
