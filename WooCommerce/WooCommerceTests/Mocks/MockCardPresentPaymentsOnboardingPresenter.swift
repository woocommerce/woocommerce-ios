import UIKit
@testable import WooCommerce

@MainActor
final class MockCardPresentPaymentsOnboardingPresenter: CardPresentPaymentsOnboardingPresenting {
    var spyShowOnboardingWasCalled = false

    nonisolated init() {}

    func showOnboardingIfRequired(from viewController: ViewControllerPresenting,
                                  readyToCollectPayment completion: @escaping () -> Void) {
        spyShowOnboardingWasCalled = true
        completion()
    }

    func showOnboardingIfRequired(from: UIViewController) async {
        spyShowOnboardingWasCalled = true
    }

    func refresh() {
        // No-op
    }
}
