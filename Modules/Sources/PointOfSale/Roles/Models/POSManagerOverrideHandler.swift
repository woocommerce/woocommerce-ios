import Foundation
import Observation

@Observable
@MainActor
final class POSManagerOverrideHandler {
    enum ApprovalResult: Equatable, Sendable {
        case completed
        /// Ending the request does not roll back an operation already admitted to persistence.
        case cancelled
    }

    typealias PINOperation = @MainActor (String) async throws(POSAuthError) -> Bool

    @ObservationIgnored private var session: POSAccessSession?
    @ObservationIgnored private var requestTask: Task<ApprovalResult, Never>?
    @ObservationIgnored private var pinInput: AsyncStream<String>.Continuation?
    @ObservationIgnored private var pendingSubmission: CheckedContinuation<Bool, Never>?
    @ObservationIgnored private var latestRequestID: UUID?

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
        if let previous = self.session, previous !== session {
            cancel()
        }
        self.session = session
        if request != nil, pinEntryState == .idle {
            refreshLockoutState()
        }
    }

    /// Keep protected side effects inside `operation`; the returned result is not an authorization grant.
    func requestApproval(for capability: POSCapability,
                         reason: String,
                         operation: PINOperation? = nil) async -> ApprovalResult {
        guard !Task.isCancelled else { return .cancelled }
        let (requestID, task) = startRequest(for: capability, reason: reason, operation: operation)
        let result = await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
        guard latestRequestID == requestID, !Task.isCancelled else { return .cancelled }
        return result
    }

    /// Runs immediately when the session grants the capability; otherwise waits for one approval.
    /// `viaOverride` lets callers defer presentation until the approval modal has closed.
    func gate(_ capability: POSCapability, reason: String, perform: @escaping (_ viaOverride: Bool) -> Void) {
        guard let session else { return }
        if session.allows(capability) {
            perform(false)
        } else {
            // Publish before returning so an immediate cancel cannot miss a queued presentation.
            _ = startRequest(for: capability, reason: reason, onSuccess: {
                guard self.session === session, !session.isLocked else { return }
                perform(true)
            })
        }
    }

    @discardableResult
    func submit(pin: String) async -> Bool {
        guard pendingSubmission == nil else { return false }
        guard let request, let task = requestTask, let pinInput else {
            pinEntryState = .error(kind: .generic)
            return false
        }
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                guard self.request?.id == request.id, !task.isCancelled, !Task.isCancelled else {
                    continuation.resume(returning: true)
                    return
                }
                pendingSubmission = continuation
                pinEntryState = .loading
                pinInput.yield(pin)
            }
        } onCancel: {
            task.cancel()
        }
    }

    func cancel() {
        requestTask?.cancel()
        latestRequestID = nil
        dismiss()
    }

    func lockoutExpired() {
        guard case .lockout = pinEntryState else { return }
        refreshLockoutState()
    }
}

private extension POSManagerOverrideHandler {
    func startRequest(for capability: POSCapability,
                      reason: String,
                      operation: PINOperation? = nil,
                      onSuccess: (() -> Void)? = nil) -> (UUID, Task<ApprovalResult, Never>) {
        cancel()
        let request = POSManagerOverrideRequest(capability: capability, reason: reason)
        latestRequestID = request.id
        self.request = request
        refreshLockoutState()
        let (pins, input) = AsyncStream.makeStream(of: String.self, bufferingPolicy: .bufferingOldest(1))
        pinInput = input
        let submitPIN: PINOperation = operation ?? { pin throws(POSAuthError) in
            guard let session = self.session else { throw .unknown }
            try await session.requestManagerApproval(withPIN: pin, for: capability)
            return true
        }
        let task = Task {
            defer {
                if self.request?.id == request.id { dismiss() }
            }
            for await pin in pins {
                guard self.request?.id == request.id, !Task.isCancelled else { return ApprovalResult.cancelled }
                do {
                    let succeeded = try await submitPIN(pin)
                    guard self.request?.id == request.id, !Task.isCancelled else { return .cancelled }
                    if succeeded {
                        dismiss()
                        // Keep legacy effects contiguous with the session's final ownership check.
                        onSuccess?()
                        return .completed
                    }
                    pinEntryState = .error(kind: .generic)
                } catch {
                    guard self.request?.id == request.id, !Task.isCancelled else { return .cancelled }
                    pinEntryState = state(for: (error as? POSAuthError) ?? .unknown)
                }
                resolveSubmission(false)
            }
            return .cancelled
        }
        requestTask = task
        return (request.id, task)
    }

    func resolveSubmission(_ result: Bool) {
        let continuation = pendingSubmission
        pendingSubmission = nil
        continuation?.resume(returning: result)
    }

    func dismiss() {
        pinInput?.finish()
        pinInput = nil
        requestTask = nil
        request = nil
        pinEntryState = .idle
        // Cancellation is not a rejected PIN and must not trigger keypad failure feedback.
        resolveSubmission(true)
    }

    func refreshLockoutState() {
        do {
            try session?.checkLockoutState()
            pinEntryState = .idle
        } catch {
            pinEntryState = state(for: error)
        }
    }

    func state(for error: POSAuthError) -> POSPINEntryState {
        switch error {
        case .invalidPIN: .error(kind: .invalidPIN)
        case .rateLimited(let until): .lockout(until: until)
        case .permanentlyLocked, .unknown: .error(kind: .generic)
        }
    }
}
