import UIKit

/// How the product form (`ProductFormViewController`) is presented.
enum ProductFormPresentationStyle {
    /// Pushed to a navigation stack.
    case navigationStack

    /// Contained in another view controller in a navigation stack.
    /// `containerViewController` is a closure that returns an optional view controller so that the container is not retained to result in a retain cycle.
    case contained(containerViewController: () -> UIViewController?)
}

extension ProductFormPresentationStyle {
    /// Determines how a product form view controller exits.
    /// - Parameter viewController: the product form view controller that is about to exit.
    /// - Parameter completion: called when the exit logic is complete.
    /// - Returns: a closure to be called that exits the product form.
    func createExitForm(viewController: UIViewController, completion: @escaping () -> Void = {}) -> (() -> Void) {
        switch self {
        case .contained:
            return {
                viewController.dismiss(animated: true, completion: completion)
            }
        case .navigationStack:
            return {
                viewController.navigationController?.popViewController(animated: true)
                completion()
            }
        }
    }
}
