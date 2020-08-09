@testable import WordPressAuthenticator


protocol ModalViewControllerPresenting {
    func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)?)
}

extension UIViewController: ModalViewControllerPresenting {}

class ModalViewControllerPresentingSpy: UIViewController {
    internal var presentedVC: UIViewController? = .none
    override func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)?) {
        presentedVC = viewControllerToPresent
    }
}
