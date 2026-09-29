import UIKit
@testable import WooCommerce

/// Reports a fixed decision synchronously; consent requests are never sent.
final class MockAgeRangeVerificationCoordinator: AgeRangeVerificationCoordinatorProtocol {
    var decision: AppAccessDecision
    var result: AgeRangeVerificationResult
    private(set) var triggers: [AgeVerificationTrigger] = []

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
        onResult(decision, result)
    }

    func startObservingConsentResponses(onResolution: @escaping @MainActor () -> Void) {
        // no-op
    }

    func requestSignificantChangeConsent(hostingWindow: UIWindow) async -> SignificantChangeConsentState {
        .notAvailable
    }
}
