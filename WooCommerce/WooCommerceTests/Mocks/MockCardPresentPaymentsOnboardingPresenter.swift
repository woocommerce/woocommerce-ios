import UIKit
@testable import WooCommerce

struct MockCardPresentPaymentsOnboardingPresenter: CardPresentPaymentsOnboardingPresenting {
    func showOnboardingIfRequired(from viewController: UIViewController,
                                  readyToCollectPayment completion: @escaping (() -> ())) {
        completion()
    }
}
