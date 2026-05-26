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
    /// In M1 capability gates are pure UI hides — there is no manager-override
    /// affordance, so callers should hide affordances when this returns `false`.
    /// Manager override returns in M3 per the plan.
    func hasCapability(_ capability: String) -> Bool

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
}
