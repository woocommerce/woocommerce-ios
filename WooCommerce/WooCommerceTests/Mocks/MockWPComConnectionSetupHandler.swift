import Foundation
@testable import WooCommerce

@MainActor
final class MockWPComConnectionSetupHandler: WPComConnectionSetupHandlerProtocol {
    weak var delegate: WPComConnectionSetupHandlerDelegate?

    private(set) var startCallCount = 0
    private(set) var retryCallCount = 0
    private(set) var cancelCallCount = 0
    private(set) var didAuthorizeWebViewConnectionCallCount = 0
    private(set) var didEncounterWebViewErrorCallCount = 0
    private(set) var didCancelWebViewCallCount = 0

    func start() {
        startCallCount += 1
    }

    func retry() {
        retryCallCount += 1
    }

    func cancel() {
        cancelCallCount += 1
    }

    func didAuthorizeWebViewConnection() {
        didAuthorizeWebViewConnectionCallCount += 1
    }

    func didEncounterWebViewError(code: Int?) {
        didEncounterWebViewErrorCallCount += 1
    }

    func didCancelWebView() {
        didCancelWebViewCallCount += 1
    }

    // MARK: - Test helpers

    func simulateStepUpdate(_ step: SetupStep, status: WPComConnectionSetupStep.Status) {
        delegate?.stepDidUpdate(step, status: status)
    }

    func simulateSetupComplete() {
        delegate?.setupDidComplete()
    }

    func simulateWebViewRequired(url: URL, siteURL: String) {
        delegate?.setupDidRequireWebView(url: url, siteURL: siteURL)
    }
}
