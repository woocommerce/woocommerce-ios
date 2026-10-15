import UIKit
@testable import WooCommerce

/// Reports a fixed decision synchronously; consent requests are never sent.
final class MockAgeRangeVerificationCoordinator: AgeRangeVerificationCoordinatorProtocol {
    var decision: AppAccessDecision
    var result: AgeRangeVerificationResult
    private(set) var triggers: [AgeVerificationTrigger] = []
    /// Runs on the hosting window before the decision is reported, to leave the window the way
    /// the system sheet does (e.g. with a controller mid-dismissal on top).
    var beforeResult: ((UIWindow) -> Void)?

    init(decision: AppAccessDecision, result: AgeRangeVerificationResult) {
        self.decision = decision
        self.result = result
    }

    func triggerAgeVerificationIfNeeded(
        hostingWindow: UIWindow,
        trigger: AgeVerificationTrigger,
        onResult: @escaping (AppAccessDecision, AgeRangeVerificationResult) -> Void
    ) {
        triggers.append(trigger)
        beforeResult?(hostingWindow)
        onResult(decision, result)
    }

    func startObservingConsentResponses(onResolution: @escaping @MainActor () -> Void) {
        // no-op
    }

    func requestSignificantChangeConsent(hostingWindow: UIWindow) async -> SignificantChangeConsentState {
        .notAvailable
    }
}
