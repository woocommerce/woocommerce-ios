import Foundation
import Observation

@Observable
@MainActor
final class POSManagerOverrideHandler {
    @ObservationIgnored private var session: POSAccessSession?
    @ObservationIgnored private var onApproved: ((POSStaff?) -> Void)?

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

    func requestApproval(for capability: POSCapability, reason: String, onApproved: ((POSStaff?) -> Void)? = nil) {
        request = POSManagerOverrideRequest(capability: capability, reason: reason)
        pinEntryState = .idle
        self.onApproved = onApproved
    }

    /// Gates `capability`: runs `perform` immediately when the configured session already grants it —
    /// including when POS roles are off, where an unrestricted session grants everything — otherwise
    /// presents the override modal and runs `perform` once an authorized staff member approves.
    /// `approver` is the staff who authorized via override, or `nil` when the operator already held the
    /// capability (so callers can attribute the action and tell the two paths apart). No-ops until the
    /// handler has been configured with a session (the override modal configures it on appear).
    func gate(_ capability: POSCapability, reason: String, perform: @escaping (_ approver: POSStaff?) -> Void) {
        guard let session else {
            return
        }
        if session.allows(capability) {
            perform(nil)
        } else {
            requestApproval(for: capability, reason: reason) { approver in
                perform(approver)
            }
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
            let approver = try await session.requestManagerApproval(withPIN: pin, for: request.capability)
            guard self.request?.id == activeRequestID else { return true }
            dismiss()
            activeOnApproved?(approver)
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
