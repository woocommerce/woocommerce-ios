import Observation

@MainActor
@Observable
final class POSPINSetupController {
    enum SubmissionResult: Equatable, Sendable {
        case confirmationRequired
        case saved
        case rejected
    }

    private(set) var isSaving = false
    private(set) var error: POSPINStoreError?
    private var firstPIN: String?
    private var draftVersion = 0
    private var saveTask: Task<Bool, Error>?
    private let validatePIN: @MainActor (String) async throws -> Void
    private let savePIN: @MainActor (String) async throws(POSPINStoreError) -> Bool

    init(validatePIN: @escaping @MainActor (String) async throws -> Void,
         savePIN: @escaping @MainActor (String) async throws(POSPINStoreError) -> Bool) {
        self.validatePIN = validatePIN
        self.savePIN = savePIN
    }

    var isConfirmingPIN: Bool { firstPIN != nil }

    func confirms(_ pin: String) -> Bool {
        firstPIN == pin
    }

    func submit(_ pin: String) async -> SubmissionResult {
        guard !isSaving else { return .rejected }
        error = nil
        guard let firstPIN else {
            let version = draftVersion
            isSaving = true
            defer { isSaving = false }
            do {
                try await validatePIN(pin)
            } catch {
                guard version == draftVersion, !Task.isCancelled, !(error is CancellationError) else { return .rejected }
                self.error = (error as? POSPINStoreError) ?? .storageFailure
                return .rejected
            }
            guard version == draftVersion, !Task.isCancelled else { return .rejected }
            self.firstPIN = pin
            return .confirmationRequired
        }
        guard pin == firstPIN else {
            self.firstPIN = nil
            return .rejected
        }
        isSaving = true
        let version = draftVersion
        let task = Task { try await savePIN(pin) }
        saveTask = task
        let result = await withTaskCancellationHandler {
            await task.result
        } onCancel: {
            task.cancel()
        }
        saveTask = nil
        let isCurrent = version == draftVersion && !Task.isCancelled
        discardDraft()
        isSaving = false
        guard isCurrent else { return .rejected }
        switch result {
        case .success(let saved): return saved ? .saved : .rejected
        case .failure(let error):
            self.error = (error as? POSPINStoreError) ?? .storageFailure
            return .rejected
        }
    }

    func cancel() -> Bool {
        guard !isSaving else { return false }
        discardDraft()
        return true
    }

    func discardDraft() {
        saveTask?.cancel()
        draftVersion += 1
        firstPIN = nil
        error = nil
    }
}
