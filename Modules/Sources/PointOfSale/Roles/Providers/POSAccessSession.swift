@MainActor
protocol POSAccessSession: AnyObject, Sendable {
    var currentStaff: POSStaff? { get }
    var isLocked: Bool { get }
    /// Whether an Admin PIN protects POS for this store on this device. Stays `true` when the stored
    /// PINs can't be read, so POS remains locked instead of opening with every action allowed.
    var isPINProtectionEnabled: Bool { get }
    /// Changes when the operator or PIN protection changes, including lock and session end, so an approval
    /// requested before can't act after.
    var accessScope: POSPINSessionTokens.Token { get }

    func refreshPINProtection() throws(POSPINStoreError)
    func beginPINChange() -> POSPINChangeRegistration

    func allows(_ capability: POSCapability) -> Bool
    func signIn(withPIN pin: String) async throws(POSAuthError)
    /// Verifies the manager PIN and confirms the approver holds `capability`; throws if the PIN is
    /// invalid or the holder lacks it.
    func requestManagerApproval(withPIN pin: String, for requiredCapability: POSCapability) async throws(POSAuthError)
    func lock()
    func endSession()
    func saveElapsedTime() async
    func checkLockoutState() async throws(POSAuthError)
}
