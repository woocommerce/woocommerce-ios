import Foundation

/// Shared protocol for POS permission checking.
///
/// In the M1 server-side design (see https://peacockp2.wordpress.com/?p=34760)
/// there is exactly one production implementation: `POSPermissionProvider`. The
/// protocol exists so the SwiftUI environment plumbing has a stable contract
/// and tests / previews can inject doubles.
public protocol POSPermissionProviding: AnyObject {
    /// The currently signed-in operator. `nil` while the lock screen is up.
    var currentOperator: POSOperator? { get }

    /// Whether the provider is explicitly locked. Persisted across app launches.
    var isLocked: Bool { get }

    /// Whether the current operator has the named capability.
    ///
    /// Use `checkPermission(_:)` instead when the call site wants to branch into
    /// a manager-override flow on insufficient capability.
    func hasCapability(_ capability: String) -> Bool

    /// Two-tier permission check: returns `.allowed` when the operator has the
    /// capability, `.requiresOverride` when they don't (in which case the call
    /// site should present a manager-override modal).
    func checkPermission(_ capability: String) -> POSPermissionResult

    /// Verifies a manager-or-above PIN locally against the cached `/staff` hashes
    /// and confirms the matched staff member holds `capability`. Returns the
    /// approver's `POSOperator` on success **without** signing them in — the
    /// current operator stays the cashier, and the caller is expected to attach
    /// `_pos_override_user_id` + `_pos_override_reason` meta to the next request.
    ///
    /// Throws `POSAuthError.invalidPIN` when the PIN doesn't match a staff
    /// member with the capability, or `POSAuthError.rateLimited` when the local
    /// rate limiter cuts in.
    func requestManagerApproval(managerPIN: String, for capability: String) async throws -> POSOperator

    /// Signs in the operator and clears any lock-screen state.
    func signIn(_ posOperator: POSOperator)

    /// Locks the session, clearing the current operator. Persisted across app launches.
    func lock()

    /// Bumps the auto-lock timer. Called by the activity tracker on any user input.
    func resetInactivityTimer()

    /// Seconds of inactivity after which the session auto-locks.
    var autoLockTimeoutSeconds: Int { get }

    /// Whether at least one staff member has a PIN configured on the backend.
    /// Drives whether the lock screen is shown at all.
    var hasAnyPINs: Bool { get }

    /// Fetches the latest staff list from `GET /wc-pos/v1/staff` and updates
    /// the cached hash list. Called on POS entry and on unrecognized-PIN retries.
    func refreshPINStatus() async
}

public extension POSPermissionProviding {
    /// Default no-op for test doubles that don't need to model the network call.
    func refreshPINStatus() async { }
}

// MARK: - POSCapability convenience

extension POSPermissionProviding {
    /// Check if the current operator has the typed capability.
    /// Usage: `permissions.hasCapability(.publishCoupons)`
    func hasCapability(_ capability: POSCapability) -> Bool {
        hasCapability(capability.rawValue)
    }

    /// Two-tier check using the typed capability enum.
    /// Usage: `permissions.checkPermission(.refundShopOrders)`
    func checkPermission(_ capability: POSCapability) -> POSPermissionResult {
        checkPermission(capability.rawValue)
    }

    /// Manager-override verify using the typed capability enum.
    func requestManagerApproval(managerPIN: String,
                                for capability: POSCapability) async throws -> POSOperator {
        try await requestManagerApproval(managerPIN: managerPIN, for: capability.rawValue)
    }
}
