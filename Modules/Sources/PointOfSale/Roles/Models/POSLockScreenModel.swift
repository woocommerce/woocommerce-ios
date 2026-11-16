import Foundation
import Observation

@Observable
@MainActor
final class POSLockScreenModel {
    private let session: POSAccessSession
    private var isSigningIn = false
    private(set) var pinEntryState: POSPINEntryState = .checking

    var isLocked: Bool { session.isLocked }

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
        guard !isSigningIn else { return false }
        isSigningIn = true
        pinEntryState = .loading
        defer { isSigningIn = false }
        do {
            try await session.signIn(withPIN: pin)
            pinEntryState = .idle
            return true
        } catch {
            pinEntryState = state(for: error)
            return false
        }
    }

    func refreshLockoutState() async {
        guard !isSigningIn else { return }
        do {
            try await session.checkLockoutState()
            switch pinEntryState {
            case .checking, .loading, .waiting, .unavailable: pinEntryState = .idle
            case .idle, .error: break
            }
        } catch {
            pinEntryState = state(for: error)
        }
    }

    func observeWait() async {
        await refreshLockoutState()
        while !Task.isCancelled && isLocked {
            let interval: Duration = switch pinEntryState {
            case .unavailable: .seconds(5)
            default: .seconds(1)
            }
            do { try await Task.sleep(for: interval) } catch { return }
            switch pinEntryState {
            case .waiting, .unavailable: await refreshLockoutState()
            case .idle, .error, .checking, .loading: break
            }
        }
    }
}

private extension POSLockScreenModel {
    func state(for error: POSAuthError) -> POSPINEntryState {
        switch error {
        case .invalidPIN: .error(kind: .invalidPIN)
        case .rateLimited(let seconds): .waiting(remainingSeconds: seconds)
        case .unknown: .unavailable
        }
    }
}
