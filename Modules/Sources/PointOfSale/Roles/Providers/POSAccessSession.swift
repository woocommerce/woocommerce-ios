@MainActor
public protocol POSAccessSession: AnyObject {
    var currentStaff: POSStaff? { get }
    var isLocked: Bool { get }
    var hasAnyPINs: Bool { get }

    func allows(_ capability: POSCapability) -> Bool
    func signIn(withPIN pin: String) async throws(POSAuthError)
    func requestManagerApproval(withPIN pin: String, for capability: POSCapability) async throws(POSAuthError)
    func lock()
    func refreshPINStatus() async
}
