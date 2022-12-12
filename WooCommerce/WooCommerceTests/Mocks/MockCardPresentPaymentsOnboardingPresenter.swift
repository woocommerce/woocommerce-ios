import UIKit
@testable import WooCommerce

final class MockCardPresentPaymentsOnboardingPresenter: CardPresentPaymentsOnboardingPresenting {
    var spyShowOnboardingWasCalled = false

    func showOnboardingIfRequired(from viewController: UIViewController) async -> () {
        spyShowOnboardingWasCalled = true
    }

    func refresh() {
        // No-op
    }
}
