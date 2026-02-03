@testable import WooCommerce

final class MockSetupHandler: WPComConnectionSetupHandlerProtocol {
    weak var delegate: WPComConnectionSetupHandlerDelegate?

    private(set) var startCalled = false
    private(set) var retryCalled = false
    private(set) var cancelCalled = false

    func start() {
        startCalled = true
    }

    func retry() {
        retryCalled = true
    }

    func cancel() {
        cancelCalled = true
    }
}
