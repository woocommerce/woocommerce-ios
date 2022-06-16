import UIKit
import Yosemite
@testable import WooCommerce

final class MockCardPresentPaymentsOnboardingPresenter: CardPresentPaymentsOnboardingPresenting {
    var spyShowOnboardingWasCalled = false

    func showOnboardingIfRequired(from viewController: UIViewController,
                                  readyToCollectPayment completion: @escaping ((CardPresentPaymentsPlugin) -> ())) {
        spyShowOnboardingWasCalled = true
        completion(.wcPay)
    }

    func refresh() {
        // No-op
    }
}
