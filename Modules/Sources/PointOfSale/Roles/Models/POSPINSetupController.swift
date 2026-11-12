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
    private var firstPIN: String?
    private let savePIN: (String) async -> Bool

    init(savePIN: @escaping (String) async -> Bool) {
        self.savePIN = savePIN
    }

    var isConfirmingPIN: Bool { firstPIN != nil }

    func submit(_ pin: String) async -> SubmissionResult {
        guard !isSaving else { return .rejected }
        hasMismatch = false
        guard let firstPIN else {
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
        firstPIN = nil
        hasMismatch = false
    }
}
