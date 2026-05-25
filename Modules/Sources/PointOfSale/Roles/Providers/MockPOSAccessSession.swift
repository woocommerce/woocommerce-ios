#if DEBUG

import Observation

@Observable
@MainActor
final class MockPOSAccessSession: POSAccessSession {
    var currentOperator: POSOperator?
    var isLocked: Bool
    var hasAnyPINs: Bool
    var signInResult: Result<POSOperator, POSAuthError>
    var signInPINs: [String] = []
    var onSignIn: (() -> Void)?

    init(currentOperator: POSOperator? = nil,
         isLocked: Bool = false,
         hasAnyPINs: Bool = true,
         signInResult: Result<POSOperator, POSAuthError> = .success(
            POSOperator(displayName: "Maya", role: "Manager", capabilities: Set(POSCapability.allCases.map(\.rawValue)))
         )) {
        self.currentOperator = currentOperator
        self.isLocked = isLocked
        self.hasAnyPINs = hasAnyPINs
        self.signInResult = signInResult
    }

    func allows(_ capability: POSCapability) -> Bool {
        currentOperator?.hasCapability(capability) == true
    }

    func signIn(withPIN pin: String) async throws(POSAuthError) {
        signInPINs.append(pin)
        onSignIn?()

        switch signInResult {
        case .success(let signedInOperator):
            currentOperator = signedInOperator
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
