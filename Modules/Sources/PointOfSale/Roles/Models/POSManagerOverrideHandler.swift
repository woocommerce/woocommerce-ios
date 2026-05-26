import Foundation
import Observation

@Observable
@MainActor
final class POSManagerOverrideHandler {
    @ObservationIgnored private var session: POSAccessSession?
    @ObservationIgnored private var onApproved: (() -> Void)?

    private(set) var request: POSManagerOverrideRequest?
    private(set) var pinEntryState: POSPINEntryState = .idle

    init(session: POSAccessSession? = nil) {
        self.session = session
    }

    #if DEBUG
    convenience init(session: POSAccessSession?,
                     initialRequest: POSManagerOverrideRequest? = nil,
                     initialPINEntryState: POSPINEntryState = .idle) {
        self.init(session: session)
        self.request = initialRequest
        self.pinEntryState = initialPINEntryState
    }
    #endif

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
            pinEntryState = .error(kind: .generic)
            return
        }

        // Pin the in-flight request so a cancel or replacement mid-await can't leak into the resolving submit.
        let activeRequestID = request.id
        let activeOnApproved = onApproved
        pinEntryState = .loading

        do {
            try await session.requestManagerApproval(withPIN: pin, for: request.capability)
            guard self.request?.id == activeRequestID else { return }
            dismiss()
            activeOnApproved?()
        } catch {
            guard self.request?.id == activeRequestID else { return }
            pinEntryState = .error(kind: errorKind(for: error))
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

    func errorKind(for error: POSAuthError) -> POSPINErrorKind {
        switch error {
        case .invalidPIN: .invalidPIN
        case .rateLimited, .permanentlyLocked, .unknown: .generic
        }
    }
}
