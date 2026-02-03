@testable import WooCommerce

@MainActor
final class MockHandlerDelegate: WPComConnectionSetupHandlerDelegate {
    private(set) var updatedSteps: Set<SetupStep> = []
    private(set) var stepStatuses: [SetupStep: WPComConnectionSetupStep.Status] = [:]
    private(set) var setupDidCompleteCalled = false

    func stepDidUpdate(_ step: SetupStep, status: WPComConnectionSetupStep.Status) {
        updatedSteps.insert(step)
        stepStatuses[step] = status
    }

    func setupDidComplete() {
        setupDidCompleteCalled = true
    }

    func lastStatusForStep(_ step: SetupStep) -> WPComConnectionSetupStep.Status? {
        stepStatuses[step]
    }

    func reset() {
        updatedSteps = []
        stepStatuses = [:]
        setupDidCompleteCalled = false
    }
}
