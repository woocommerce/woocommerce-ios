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

    /// Whether the cached staff list has at least one PIN configured. The lock-screen overlay
    /// uses this AND `isLocked` together: with no PINs there is no security boundary to enforce,
    /// so the screen stays hidden even if `isLocked` is briefly true (initial state, transient
    /// fetch failure with an empty cache, etc.).
    var hasAnyPINs: Bool {
        session.hasAnyPINs
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
