import UIKit

/// How the product form (`ProductFormViewController`) is presented.
enum ProductFormPresentationStyle {
    /// Pushed to a navigation stack.
    case navigationStack

    /// Contained in another view controller in a navigation stack.
    case contained(containerViewController: UIViewController)
}

extension ProductFormPresentationStyle {
    /// Determines how a product form view controller exits.
    /// - Parameter viewController: the product form view controller that is about to exit.
    /// - Returns: a closure to be called that exits the product form.
    func createExitForm(viewController: UIViewController) -> (() -> Void) {
        switch self {
        case .contained:
            return {
                viewController.dismiss(animated: true, completion: nil)
            }
        case .navigationStack:
            return {
                viewController.navigationController?.popViewController(animated: true)
            }
        }
    }
}
