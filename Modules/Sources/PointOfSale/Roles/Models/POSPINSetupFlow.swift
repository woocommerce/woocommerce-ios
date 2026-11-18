import Observation

/// Presentation pauses run alongside that work and never delay saving.
@MainActor
@Observable
final class POSPINSetupFlow {
    let configuration: Configuration

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

    init(configuration: Configuration, setup: POSPINSetupController,
         sleep: @escaping @MainActor (Duration) async throws -> Void = { try await Task.sleep(for: $0) }) {
        self.configuration = configuration
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

    func continueFromSuccess() -> Bool {
        guard step == .saved else { return false }
        switch configuration.successAction {
        case .offerGuidedAccess:
            step = .guidedAccessOffer
            return false
        case .done:
            return true
        }
    }

    func close() -> Bool {
        guard canClose else {
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

private extension POSPINSetupFlow {
    func choose(_ pin: String, request: Int) async -> Bool {
        async let hold: Void = pause(Constants.filledDotsHold)
        let result = await setup.submit(pin)
        await hold
        guard request == generation else {
            return false
        }
        guard result == .confirmationRequired else {
            showEntryFeedback(.failure(setup.error ?? .storageFailure), request: request)
            return false
        }
        isProcessing = false
        show(.confirm, feedback: nil)
        return true
    }

    func confirm(_ pin: String, request: Int) async -> Bool {
        guard setup.confirms(pin) else {
            setup.discardDraft()
            showEntryFeedback(.mismatch, request: request)
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
            show(.choose, feedback: .failure(setup.error ?? .storageFailure))
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

    func showEntryFeedback(_ feedback: Feedback, request: Int) {
        Task { @MainActor in
            await pause(Constants.failedEntryPause)
            guard request == generation else {
                return
            }
            isProcessing = false
            if feedback == .mismatch {
                show(.choose, feedback: nil)
                let shown = generation
                await pause(Constants.mismatchMessageDelay)
                guard shown == generation, !isProcessing else {
                    return
                }
            }
            self.feedback = feedback
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
        static let failedEntryPause: Duration = .milliseconds(550)
        static let mismatchMessageDelay: Duration = .milliseconds(500)
    }
}
