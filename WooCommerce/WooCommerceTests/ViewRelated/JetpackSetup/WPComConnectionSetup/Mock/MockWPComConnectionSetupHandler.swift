import Foundation
@testable import WooCommerce

@MainActor
final class MockWPComConnectionSetupHandler: WPComConnectionSetupHandlerProtocol {
    weak var delegate: WPComConnectionSetupHandlerDelegate?

    private(set) var startCallCount = 0
    private(set) var retryCallCount = 0
    private(set) var cancelCallCount = 0

    func start() {
        startCallCount += 1
    }

    func retry() {
        retryCallCount += 1
    }

    func cancel() {
        cancelCallCount += 1
    }

    // MARK: - Test helpers

    func simulateStepUpdate(_ step: SetupStep, status: WPComConnectionSetupHandler.StepStatus) {
        delegate?.stepDidUpdate(step, status: status)
    }

    func simulateSetupComplete() {
        delegate?.setupDidComplete()
    }
}
