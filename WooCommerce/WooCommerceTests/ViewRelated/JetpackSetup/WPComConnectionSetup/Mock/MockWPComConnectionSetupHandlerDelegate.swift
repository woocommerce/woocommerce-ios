@testable import WooCommerce

@MainActor
final class MockWPComConnectionSetupHandlerDelegate: WPComConnectionSetupHandlerDelegate {
    private(set) var updatedSteps: Set<SetupStep> = []
    private(set) var stepStatuses: [SetupStep: WPComConnectionSetupHandler.StepStatus] = [:]
    private(set) var setupDidCompleteCalled = false

    var onStepUpdate: ((SetupStep, WPComConnectionSetupHandler.StepStatus) -> Void)?
    var onSetupComplete: (() -> Void)?

    func stepDidUpdate(_ step: SetupStep, status: WPComConnectionSetupHandler.StepStatus) {
        updatedSteps.insert(step)
        stepStatuses[step] = status
        onStepUpdate?(step, status)
    }

    func setupDidComplete() {
        setupDidCompleteCalled = true
        onSetupComplete?()
    }

    func lastStatusForStep(_ step: SetupStep) -> WPComConnectionSetupHandler.StepStatus? {
        stepStatuses[step]
    }
}
