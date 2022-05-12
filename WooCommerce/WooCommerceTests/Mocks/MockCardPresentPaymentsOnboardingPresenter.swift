import UIKit
@testable import WooCommerce

final class MockCardPresentPaymentsOnboardingPresenter: CardPresentPaymentsOnboardingPresenting {
    var spyShowOnboardingWasCalled = false

    func showOnboardingIfRequired(from viewController: UIViewController,
                                  readyToCollectPayment completion: @escaping (() -> ())) {
        spyShowOnboardingWasCalled = true
        completion()
    }

    func refresh() {
        // No-op
    }
}
