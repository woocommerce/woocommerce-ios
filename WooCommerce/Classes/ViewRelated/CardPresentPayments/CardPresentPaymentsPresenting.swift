import UIKit

protocol CardPresentPaymentsPresenting {
    func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)?)
    func present(_ viewControllerToPresent: UIViewController, animated: Bool)
    func dismiss(animated: Bool, completion: (() -> Void)?)
    func dismiss(animated: Bool)
    func show(_ vc: UIViewController, sender: Any?)
    var presentedViewController: UIViewController? { get }
    var navigationController: UINavigationController? { get }
}

extension UIViewController: CardPresentPaymentsPresenting {
    func present(_ viewControllerToPresent: UIViewController, animated: Bool) {
        present(viewControllerToPresent, animated: animated, completion: nil)
    }

    func dismiss(animated: Bool) {
        dismiss(animated: animated, completion: nil)
    }
}
