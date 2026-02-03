@testable import WooCommerce

@MainActor
final class MockWPComConnectionSetupHandlerDelegate: WPComConnectionSetupHandlerDelegate {
    private(set) var updatedSteps: Set<SetupStep> = []
    private(set) var stepStatuses: [SetupStep: WPComConnectionSetupStep.Status] = [:]
    private(set) var setupDidCompleteCalled = false

    var onStepUpdate: ((SetupStep, WPComConnectionSetupStep.Status) -> Void)?
    var onSetupComplete: (() -> Void)?

    func stepDidUpdate(_ step: SetupStep, status: WPComConnectionSetupStep.Status) {
        updatedSteps.insert(step)
        stepStatuses[step] = status
        onStepUpdate?(step, status)
    }

    func setupDidComplete() {
        setupDidCompleteCalled = true
        onSetupComplete?()
    }

    func lastStatusForStep(_ step: SetupStep) -> WPComConnectionSetupStep.Status? {
        stepStatuses[step]
    }
}
