@MainActor
protocol POSAccessSession: AnyObject {
    var currentStaff: POSStaff? { get }
    var isLocked: Bool { get }
    /// Whether the cached staff list has at least one PIN on file — i.e. POS access is PIN-gated.
    /// Gating is cache-driven, not connection-driven: an existing cache still locks while offline.
    /// Only an empty cache (never fetched, or cleared on logout / when roles are disabled
    /// server-side) reports `false` — no gating, no lock screen.
    var hasAnyPINs: Bool { get }

    func allows(_ capability: POSCapability) -> Bool
    func signIn(withPIN pin: String) async throws(POSAuthError)
    /// Verifies the manager PIN and confirms the approver holds `capability`; throws if the PIN is
    /// invalid or the holder lacks it.
    func requestManagerApproval(withPIN pin: String, for capability: POSCapability) async throws(POSAuthError)
    func lock()
    func checkLockoutState() throws(POSAuthError)
    func refreshPINStatus() async

    /// Wipes the persisted staff cache for the current site. Called on logout and site-switch
    /// so stale credentials do not survive across sessions.
    func clearStaffCache()
}
