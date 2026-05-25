import Foundation
import Observation

@Observable
@MainActor
final class POSLockScreenModel {
    private let session: POSAccessSession

    var pinEntryState: POSPINEntryState = .idle

    var isLocked: Bool {
        session.isLocked
    }

    init(session: POSAccessSession) {
        self.session = session
    }

    func signIn(withPIN pin: String) async {
        pinEntryState = .loading

        do {
            try await session.signIn(withPIN: pin)
            pinEntryState = .idle
        } catch {
            pinEntryState = .error(message: message(for: error))
        }
    }
}

private extension POSLockScreenModel {
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
