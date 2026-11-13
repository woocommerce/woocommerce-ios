import Observation

@MainActor
@Observable
final class POSPINSetupController {
    enum SubmissionResult: Equatable, Sendable {
        case confirmationRequired
        case saved
        case rejected
    }

    private(set) var hasMismatch = false
    private(set) var isSaving = false
    private(set) var error: POSPINStoreError?
    private var firstPIN: String?
    private var draftVersion = 0
    private let validatePIN: @MainActor (String) async throws -> Void
    private let savePIN: @MainActor (String) async -> Bool

    init(validatePIN: @escaping @MainActor (String) async throws -> Void,
         savePIN: @escaping @MainActor (String) async -> Bool) {
        self.validatePIN = validatePIN
        self.savePIN = savePIN
    }

    var isConfirmingPIN: Bool { firstPIN != nil }

    func submit(_ pin: String) async -> SubmissionResult {
        guard !isSaving else { return .rejected }
        hasMismatch = false
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
            hasMismatch = true
            return .rejected
        }
        isSaving = true
        let saved = await savePIN(pin)
        discardDraft()
        isSaving = false
        return saved ? .saved : .rejected
    }

    func cancel() -> Bool {
        guard !isSaving else { return false }
        discardDraft()
        return true
    }

    func discardDraft() {
        draftVersion += 1
        firstPIN = nil
        hasMismatch = false
        error = nil
    }
}
