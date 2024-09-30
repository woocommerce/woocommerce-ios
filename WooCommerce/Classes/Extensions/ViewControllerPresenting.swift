import UIKit

/// Abstracts `UIViewController` usage in features (currently in card present payments) so that the UI/UX can also be implemented in
/// SwiftUI while not affecting the pre-existing UIKit implementation.
protocol ViewControllerPresenting: AnyObject {
    func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)?)
    func present(_ viewControllerToPresent: UIViewController, animated: Bool)
    func dismiss(animated: Bool, completion: (() -> Void)?)
    func dismiss(animated: Bool)
    func show(_ vc: UIViewController, sender: Any?)
    var presentedViewController: UIViewController? { get }
    var navigationController: UINavigationController? { get }
}

extension UIViewController: ViewControllerPresenting {
    func present(_ viewControllerToPresent: UIViewController, animated: Bool) {
        present(viewControllerToPresent, animated: animated, completion: nil)
    }

    func dismiss(animated: Bool) {
        dismiss(animated: animated, completion: nil)
    }
}

/// When used instead of `UIViewController`, UI/UX is expected to be implemented separately from the original UIKit implementation with
/// the `UIViewController`.
final class NullViewControllerPresenting: ViewControllerPresenting {
    func present(_ viewControllerToPresent: UIViewController, animated: Bool) {
        // no-op
    }

    func dismiss(animated: Bool) {
        // no-op
    }

    func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)?) {
        // no-op
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        // no-op
    }

    func show(_ vc: UIViewController, sender: Any?) {
        // no-op
    }

    var presentedViewController: UIViewController?

    var navigationController: UINavigationController?
}
