import Foundation
import Observation

@Observable
@MainActor
final class POSLockScreenModel {
    private let session: POSAccessSession

    private(set) var pinEntryState: POSPINEntryState = .idle
    private(set) var isRefreshing: Bool

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

    /// Drives which content the lock screen renders. Derived from `pinStatus` and
    /// `isRefreshing` so the view stays declarative.
    var content: Content {
        switch pinStatus {
        case .present, .absent:
            // .absent shouldn't reach the lock screen (overlay hides), but render the numpad
            // defensively in case of a brief state-transition frame.
            return .pinEntry
        case .unknown:
            return isRefreshing ? .loading : .unavailable
        }
    }

    init(session: POSAccessSession) {
        self.session = session
        // Assume the lock screen will call `refreshPINStatus()` in `.task` on first appear,
        // so initialize as refreshing when the session starts uncertain. Avoids a one-frame
        // flash of the unavailable state on cold start.
        self.isRefreshing = session.pinStatus == .unknown
        do {
            try session.checkLockoutState()
        } catch {
            pinEntryState = state(for: error)
        }
    }

    #if DEBUG
    convenience init(session: POSAccessSession,
                     initialPinEntryState: POSPINEntryState = .idle,
                     isRefreshing: Bool? = nil) {
        self.init(session: session)
        self.pinEntryState = initialPinEntryState
        if let isRefreshing {
            self.isRefreshing = isRefreshing
        }
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
        isRefreshing = true
        await session.refreshPINStatus()
        isRefreshing = false
    }
}

extension POSLockScreenModel {
    /// Mutually-exclusive content states the lock screen can render. `pinEntry` is the
    /// numpad happy path; `loading` and `unavailable` cover the two `.unknown` sub-cases.
    enum Content: Equatable {
        case loading
        case pinEntry
        case unavailable
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
