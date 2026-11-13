import Foundation
import Observation

@Observable
@MainActor
final class POSManagerOverrideHandler {
    @ObservationIgnored private var session: POSAccessSession?
    @ObservationIgnored private var onApproved: (() -> Void)?
    @ObservationIgnored private var submitPIN: (@MainActor (String) async throws(POSAuthError) -> Bool)?
    @ObservationIgnored private var onCancel: (() -> Void)?
    @ObservationIgnored private var submission: Task<Bool, Never>?

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

    func requestApproval(for capability: POSCapability,
                         reason: String,
                         submitPIN: (@MainActor (String) async throws(POSAuthError) -> Bool)? = nil,
                         onCancel: (() -> Void)? = nil,
                         onApproved: (() -> Void)? = nil) {
        cancel()
        request = POSManagerOverrideRequest(capability: capability, reason: reason)
        pinEntryState = .idle
        self.onApproved = onApproved
        self.submitPIN = submitPIN
        self.onCancel = onCancel
    }

    /// Gates `capability`: runs `perform` immediately when the configured session already grants it —
    /// including when POS roles are off, where an unrestricted session grants everything — otherwise
    /// presents the override modal and runs `perform` once an authorized staff member approves.
    /// `viaOverride` is `true` only on the approval path, so a caller can defer work that must wait for
    /// the override modal to dismiss. No-ops until the handler has been configured with a session (the
    /// override modal configures it on appear).
    func gate(_ capability: POSCapability, reason: String, perform: @escaping (_ viaOverride: Bool) -> Void) {
        guard let session else {
            return
        }
        if session.allows(capability) {
            perform(false)
        } else {
            requestApproval(for: capability, reason: reason, onApproved: {
                perform(true)
            })
        }
    }

    @discardableResult
    func submit(pin: String) async -> Bool {
        guard submission == nil else { return false }
        guard let request, submitPIN != nil || session != nil else {
            pinEntryState = .error(kind: .generic)
            return false
        }

        // Pin the in-flight request so a cancel or replacement mid-await can't leak into the resolving submit.
        let activeRequestID = request.id
        let activeOnApproved = onApproved
        let activeSubmitPIN = submitPIN
        pinEntryState = .loading
        let task = Task {
            defer {
                if self.request?.id == activeRequestID {
                    submission = nil
                    if Task.isCancelled { cancel() }
                }
            }
            guard self.request?.id == activeRequestID, !Task.isCancelled else { return activeSubmitPIN == nil }
            do {
                let succeeded: Bool
                if let activeSubmitPIN {
                    succeeded = try await activeSubmitPIN(pin)
                } else if let session {
                    try await session.requestManagerApproval(withPIN: pin, for: request.capability)
                    succeeded = true
                } else {
                    succeeded = false
                }
                guard self.request?.id == activeRequestID, !Task.isCancelled else { return activeSubmitPIN == nil }
                guard succeeded else {
                    pinEntryState = .error(kind: .generic)
                    return false
                }
                dismiss()
                activeOnApproved?()
                return true
            } catch {
                guard self.request?.id == activeRequestID, !Task.isCancelled else { return activeSubmitPIN == nil }
                pinEntryState = state(for: (error as? POSAuthError) ?? .unknown)
                return false
            }
        }
        submission = task
        return await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
    }

    func cancel() {
        let activeOnCancel = onCancel
        dismiss()
        activeOnCancel?()
    }
}

private extension POSManagerOverrideHandler {
    func dismiss() {
        submission?.cancel()
        submission = nil
        request = nil
        pinEntryState = .idle
        onApproved = nil
        submitPIN = nil
        onCancel = nil
    }

    // TODO: route .rateLimited(until:) to a lockout state when the manager override flow is wired in.
    func state(for error: POSAuthError) -> POSPINEntryState {
        switch error {
        case .invalidPIN: .error(kind: .invalidPIN)
        case .rateLimited, .permanentlyLocked, .unknown: .error(kind: .generic)
        }
    }
}
