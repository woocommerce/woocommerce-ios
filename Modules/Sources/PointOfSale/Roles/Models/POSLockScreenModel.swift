import Foundation
import Observation

@Observable
@MainActor
final class POSLockScreenModel {
    private let session: POSAccessSession

    private(set) var pinEntryState: POSPINEntryState = .idle

    var isLocked: Bool {
        session.isLocked
    }

    init(session: POSAccessSession) {
        self.session = session
    }

    #if DEBUG
    convenience init(session: POSAccessSession, initialPinEntryState: POSPINEntryState) {
        self.init(session: session)
        self.pinEntryState = initialPinEntryState
    }
    #endif

    func signIn(withPIN pin: String) async {
        pinEntryState = .loading

        do {
            try await session.signIn(withPIN: pin)
            pinEntryState = .idle
        } catch {
            pinEntryState = state(for: error)
        }
    }
}

private extension POSLockScreenModel {
    func state(for error: POSAuthError) -> POSPINEntryState {
        switch error {
        case .invalidPIN: .error(kind: .invalidPIN)
        case .rateLimited(let until): .lockout(until: until)
        case .permanentlyLocked, .unknown: .error(kind: .generic)
        }
    }
}
