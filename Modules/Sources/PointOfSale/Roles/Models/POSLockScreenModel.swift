import Foundation
import Observation

@Observable
@MainActor
final class POSLockScreenModel {
    private let session: POSAccessSession

    private(set) var isLocked: Bool
    private(set) var hasAnyPINs: Bool
    var pinEntryState: POSPINEntryState = .idle

    init(session: POSAccessSession) {
        self.session = session
        self.isLocked = session.isLocked
        self.hasAnyPINs = session.hasAnyPINs
        observeSessionState()
    }

    func refreshPINStatus() async {
        await session.refreshPINStatus()
        syncSessionState()
    }

    func signIn(withPIN pin: String) async {
        pinEntryState = .loading

        do {
            try await session.signIn(withPIN: pin)
            pinEntryState = .idle
        } catch {
            pinEntryState = .error(message: message(for: error))
        }

        syncSessionState()
    }

    func syncSessionState() {
        isLocked = session.isLocked
        hasAnyPINs = session.hasAnyPINs
    }
}

private extension POSLockScreenModel {
    func observeSessionState() {
        withObservationTracking {
            _ = session.isLocked
            _ = session.hasAnyPINs
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.syncSessionState()
                self?.observeSessionState()
            }
        }
    }

    func message(for error: POSAuthError) -> String {
        switch error {
        case .invalidPIN:
            Localization.invalidPIN
        case .unknown:
            Localization.unknownError
        }
    }

    enum Localization {
        static let invalidPIN = NSLocalizedString(
            "pos.lockScreen.invalidPIN",
            value: "Incorrect PIN. Try again.",
            comment: "Error shown on the POS lock screen when the entered PIN is invalid."
        )
        static let unknownError = NSLocalizedString(
            "pos.lockScreen.unknownError",
            value: "Something went wrong. Try again.",
            comment: "Error shown on the POS lock screen when unlocking fails for an unknown reason."
        )
    }
}
