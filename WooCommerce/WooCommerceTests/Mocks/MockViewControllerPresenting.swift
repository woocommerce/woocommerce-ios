import Foundation
import UIKit

@testable import WooCommerce

final class MockViewControllerPresenting: ViewControllerPresenting {
    func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)?) {
        // no-op
    }

    func present(_ viewControllerToPresent: UIViewController, animated: Bool) {
        // no-op
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        // no-op
    }

    func dismiss(animated: Bool) {
        // no-op
    }

    func show(_ vc: UIViewController, sender: Any?) {
        // no-op
    }

    var presentedViewController: UIViewController? = nil

    var navigationController: UINavigationController? = nil
}
