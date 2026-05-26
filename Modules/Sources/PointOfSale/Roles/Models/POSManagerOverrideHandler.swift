import Foundation
import Observation

@Observable
@MainActor
final class POSManagerOverrideHandler {
    @ObservationIgnored private var session: POSAccessSession?
    @ObservationIgnored private var onApproved: (() -> Void)?

    var request: POSManagerOverrideRequest?
    var pinEntryState: POSPINEntryState = .idle

    init(session: POSAccessSession? = nil) {
        self.session = session
    }

    func configure(session: POSAccessSession) {
        self.session = session
    }

    func requestApproval(for capability: POSCapability, reason: String, onApproved: (() -> Void)? = nil) {
        request = POSManagerOverrideRequest(capability: capability, reason: reason)
        pinEntryState = .idle
        self.onApproved = onApproved
    }

    func submit(pin: String) async {
        guard let request, let session else {
            pinEntryState = .error(message: Localization.unknownError)
            return
        }

        pinEntryState = .loading

        do {
            try await session.requestManagerApproval(withPIN: pin, for: request.capability)
            let approvedAction = onApproved
            dismiss()
            approvedAction?()
        } catch {
            pinEntryState = .error(message: message(for: error))
        }
    }

    func cancel() {
        dismiss()
    }
}

private extension POSManagerOverrideHandler {
    func dismiss() {
        request = nil
        pinEntryState = .idle
        onApproved = nil
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
            "pos.managerOverride.invalidPIN",
            value: "Incorrect PIN. Try again.",
            comment: "Error shown on the POS manager approval modal when the entered PIN is invalid."
        )
        static let unknownError = NSLocalizedString(
            "pos.managerOverride.unknownError",
            value: "Something went wrong. Try again.",
            comment: "Error shown on the POS manager approval modal when approval fails for an unknown reason."
        )
    }
}
