import Observation

/// Presents first Admin PIN setup on top of `POSPINSetupController`, which owns validation and the single save.
/// Presentation pauses run alongside that work and never delay saving.
@MainActor
@Observable
final class POSAdminPINOnboarding {
    enum Step: Equatable {
        case choose
        case confirm
        case saving
        case saved
        case guidedAccessOffer
    }

    enum Feedback: Equatable {
        case mismatch
        case failure(POSPINStoreError)
    }

    private(set) var step = Step.choose
    private(set) var feedback: Feedback?
    private(set) var pageID = 0
    private var isProcessing = false
    @ObservationIgnored private var generation = 0
    private let setup: POSPINSetupController
    private let sleep: @MainActor (Duration) async throws -> Void

    init(setup: POSPINSetupController,
         sleep: @escaping @MainActor (Duration) async throws -> Void = { try await Task.sleep(for: $0) }) {
        self.setup = setup
        self.sleep = sleep
    }

    var pinEntryState: POSPINEntryState {
        isProcessing ? .loading : .idle
    }

    var canGoBack: Bool {
        step == .confirm && !isProcessing
    }

    var canClose: Bool {
        !setup.isSaving
    }

    func submit(_ pin: String) async -> Bool {
        guard !isProcessing, step == .choose || step == .confirm else {
            return false
        }
        let request = generation
        isProcessing = true
        if step == .choose {
            feedback = nil
            return await choose(pin, request: request)
        }
        return await confirm(pin, request: request)
    }

    func goBack() {
        guard canGoBack else {
            return
        }
        setup.discardDraft()
        show(.choose, feedback: nil)
    }

    func continueToGuidedAccessOffer() {
        guard step == .saved else {
            return
        }
        step = .guidedAccessOffer
    }

    /// Returns `false` while the PIN is being checked or saved.
    func close() -> Bool {
        guard setup.cancel() else {
            return false
        }
        discard()
        return true
    }

    /// Ignores pending results after the flow disappears, for example when POS locks.
    func discard() {
        generation += 1
        isProcessing = false
        setup.discardDraft()
    }
}

private extension POSAdminPINOnboarding {
    func choose(_ pin: String, request: Int) async -> Bool {
        async let hold: Void = pause(Constants.filledDotsHold)
        let result = await setup.submit(pin)
        await hold
        guard request == generation else {
            return false
        }
        isProcessing = false
        guard result == .confirmationRequired else {
            feedback = .failure(setup.error ?? .storageFailure)
            return false
        }
        show(.confirm, feedback: nil)
        return true
    }

    func confirm(_ pin: String, request: Int) async -> Bool {
        guard setup.confirms(pin) else {
            setup.discardDraft()
            showMismatch(request: request)
            return false
        }
        async let presentation: Void = presentSaving(request: request)
        let result = await setup.submit(pin)
        await presentation
        guard request == generation else {
            return false
        }
        isProcessing = false
        guard result == .saved else {
            show(.choose, feedback: .failure(.storageFailure))
            return false
        }
        step = .saved
        return true
    }

    func presentSaving(request: Int) async {
        await pause(Constants.filledDotsHold)
        guard request == generation else {
            return
        }
        step = .saving
        await pause(Constants.minimumSavingDuration)
    }

    /// The entry reports the mismatch at once so the dots shake, then slides back to Choose and explains it.
    func showMismatch(request: Int) {
        Task { @MainActor in
            await pause(Constants.mismatchShake)
            guard request == generation else {
                return
            }
            isProcessing = false
            show(.choose, feedback: nil)
            let shown = generation
            await pause(Constants.mismatchMessageDelay)
            guard shown == generation, !isProcessing else {
                return
            }
            feedback = .mismatch
        }
    }

    func show(_ step: Step, feedback: Feedback?) {
        generation += 1
        pageID += 1
        self.step = step
        self.feedback = feedback
    }

    func pause(_ duration: Duration) async {
        try? await sleep(duration)
    }

    enum Constants {
        static let filledDotsHold: Duration = .milliseconds(500)
        static let minimumSavingDuration: Duration = .seconds(1)
        static let mismatchShake: Duration = .milliseconds(550)
        static let mismatchMessageDelay: Duration = .milliseconds(500)
    }
}
