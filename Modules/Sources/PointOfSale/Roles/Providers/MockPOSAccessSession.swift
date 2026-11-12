#if DEBUG

import Observation

@Observable
@MainActor
final class MockPOSAccessSession: POSAccessSession {
    var currentStaff: POSStaff?
    var isLocked: Bool
    var isPINProtectionEnabled: Bool
    var signInResult: Result<POSStaff, POSAuthError>
    var managerApprovalResult: Result<Void, POSAuthError>
    var checkLockoutResult: Result<Void, POSAuthError>
    var signInPINs: [String] = []
    var managerApprovalPINs: [String] = []
    var managerApprovalCapabilities: [POSCapability] = []
    var onSignIn: (() -> Void)?
    var onManagerApproval: (() -> Void)?
    private(set) var lockCallCount: Int = 0

    init(currentStaff: POSStaff? = nil,
         isLocked: Bool = false,
         isPINProtectionEnabled: Bool = true,
         signInResult: Result<POSStaff, POSAuthError> = .success(POSLocalRole.admin.staff),
         managerApprovalResult: Result<Void, POSAuthError> = .success(()),
         checkLockoutResult: Result<Void, POSAuthError> = .success(())) {
        self.currentStaff = currentStaff
        self.isLocked = isLocked
        self.isPINProtectionEnabled = isPINProtectionEnabled
        self.signInResult = signInResult
        self.managerApprovalResult = managerApprovalResult
        self.checkLockoutResult = checkLockoutResult
    }

    func refreshPINProtection() throws(POSPINStoreError) {}
    func beginPINChange() throws(POSPINStoreError) -> POSPINChangeRegistration { POSPINChangeRegistration {} }

    func allows(_ capability: POSCapability) -> Bool {
        !isPINProtectionEnabled || currentStaff?.hasCapability(capability) == true
    }

    func signIn(withPIN pin: String) async throws(POSAuthError) {
        signInPINs.append(pin)
        onSignIn?()

        switch signInResult {
        case .success(let signedInStaff):
            currentStaff = signedInStaff
            isLocked = false
        case .failure(let error):
            throw error
        }
    }

    func requestManagerApproval(withPIN pin: String, for capability: POSCapability) async throws(POSAuthError) {
        managerApprovalPINs.append(pin)
        managerApprovalCapabilities.append(capability)
        onManagerApproval?()

        switch managerApprovalResult {
        case .success:
            break
        case .failure(let error):
            throw error
        }
    }

    func lock() {
        isLocked = true
        lockCallCount += 1
    }

    func endSession() {}
    func recover() async throws(POSAuthError) { throw .unknown }
    func checkpoint() async {}

    func checkLockoutState() async throws(POSAuthError) {
        switch checkLockoutResult {
        case .success:
            break
        case .failure(let error):
            throw error
        }
    }
}

#endif
