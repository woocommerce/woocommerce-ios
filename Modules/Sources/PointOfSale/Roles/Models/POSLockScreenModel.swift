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

    /// Tri-state reflecting whether the cached staff list has any PINs. The overlay treats
    /// `.absent` as "no security boundary, skip the lock screen"; `.unknown` and `.present`
    /// both keep the boundary up. Distinguishing `.unknown` from `.absent` prevents an offline
    /// first-open with an empty cache from auto-unlocking the dashboard.
    var pinStatus: POSPINStatus {
        session.pinStatus
    }

    init(session: POSAccessSession) {
        self.session = session
        do {
            try session.checkLockoutState()
        } catch {
            pinEntryState = state(for: error)
        }
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

    func lockoutExpired() {
        guard case .lockout = pinEntryState else { return }
        pinEntryState = .idle
    }

    func refreshPINStatus() async {
        await session.refreshPINStatus()
    }
}

private extension POSLockScreenModel {
    func state(for error: POSAuthError) -> POSPINEntryState {
        switch error {
        case .invalidPIN: .error(kind: .invalidPIN)
        case .rateLimited(let until): .lockout(until: until)
        case .permanentlyLocked, .unknown, .staffFetchFailed: .error(kind: .generic)
        }
    }
}
