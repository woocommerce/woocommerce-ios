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

    /// Gates `capability`: runs `perform` immediately when the configured session already grants it,
    /// otherwise presents the override modal and runs `perform` once an authorized staff member
    /// approves. No-ops until the handler has been configured with a session (the override modal
    /// configures it on appear).
    func gate(_ capability: POSCapability, reason: String, perform: @escaping () -> Void) {
        guard let session else {
            return
        }
        if session.allows(capability) {
            perform()
        } else {
            requestApproval(for: capability, reason: reason, onApproved: perform)
        }
    }

    @discardableResult
    func submit(pin: String) async -> Bool {
        guard let request, let session else {
            pinEntryState = .error(kind: .generic)
            return false
        }

        // Pin the in-flight request so a cancel or replacement mid-await can't leak into the resolving submit.
        let activeRequestID = request.id
        let activeOnApproved = onApproved
        pinEntryState = .loading

        do {
            try await session.requestManagerApproval(withPIN: pin, for: request.capability)
            guard self.request?.id == activeRequestID else { return true }
            dismiss()
            activeOnApproved?()
            return true
        } catch {
            guard self.request?.id == activeRequestID else { return true }
            pinEntryState = state(for: error)
            return false
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

    // TODO: route .rateLimited(until:) to a lockout state when the manager override flow is wired in.
    func state(for error: POSAuthError) -> POSPINEntryState {
        switch error {
        case .invalidPIN: .error(kind: .invalidPIN)
        case .rateLimited, .permanentlyLocked, .unknown, .staffFetchFailed: .error(kind: .generic)
        }
    }
}
