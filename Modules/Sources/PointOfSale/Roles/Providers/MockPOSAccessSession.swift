#if DEBUG

import Observation

@Observable
@MainActor
final class MockPOSAccessSession: POSAccessSession {
    var currentStaff: POSStaff?
    var isLocked: Bool
    var hasAnyPINs: Bool
    var signInResult: Result<POSStaff, POSAuthError>
    var signInPINs: [String] = []
    var onSignIn: (() -> Void)?

    init(currentStaff: POSStaff? = nil,
         isLocked: Bool = false,
         hasAnyPINs: Bool = true,
         signInResult: Result<POSStaff, POSAuthError> = .success(
            POSStaff(displayName: "Maya", role: "Manager", capabilities: Set(POSCapability.allCases.map(\.rawValue)))
         )) {
        self.currentStaff = currentStaff
        self.isLocked = isLocked
        self.hasAnyPINs = hasAnyPINs
        self.signInResult = signInResult
    }

    func allows(_ capability: POSCapability) -> Bool {
        currentStaff?.hasCapability(capability) == true
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

    func requestManagerApproval(withPIN pin: String, for capability: POSCapability) async throws(POSAuthError) {}

    func lock() {
        isLocked = true
    }

    func refreshPINStatus() async {}
}

#endif
