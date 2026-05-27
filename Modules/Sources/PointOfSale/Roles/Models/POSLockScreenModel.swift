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

    @discardableResult
    func signIn(withPIN pin: String) async -> Bool {
        pinEntryState = .loading

        do {
            try await session.signIn(withPIN: pin)
            pinEntryState = .idle
            return true
        } catch {
            pinEntryState = state(for: error)
            return false
        }
    }

    func refresh() async {
        await session.refreshPINStatus()
        do {
            try session.checkLockoutState()
        } catch {
            pinEntryState = state(for: error)
        }
    }

    func lockoutExpired() {
        guard case .lockout = pinEntryState else { return }
        pinEntryState = .idle
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
