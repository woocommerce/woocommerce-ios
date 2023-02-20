import UIKit

// MARK: Presentation Helpers
extension SupportFormHostingController {

    /// Shows the `SupportForm` according to it's parent view controller hierarchy.
    /// Code copied from `ZendeskManager`.
    ///
    func show(from controller: UIViewController) {
        // Got some duck typing going on in here. Sorry.

        // If the controller is a UIViewController, set the modal display for iPad.
        if !controller.isKind(of: UINavigationController.self) && UIDevice.current.userInterfaceIdiom == .pad {
            return showViewModally(from: controller)
        }

        if let navController = controller as? UINavigationController {
            return navController.pushViewController(self, animated: true)
        }

        if let navController = controller.navigationController {
            return navController.pushViewController(self, animated: true)
        }

        showViewModally(from: controller)
    }

    /// Dismisses the view depending on it's presenting `ViewController` hierarchy.
    ///
    func dismissView() {
        // Only pop the view if we are inside a navigation stack and the support form is not the root view controller
        if let navigationController, navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
        } else {
            // For any other case, attempt a modal dismiss.
            dismiss(animated: true)
        }
    }

    /// Shows the `SupportForm` modally inside a NavigationController.
    ///
    private func showViewModally(from controller: UIViewController) {
        addCloseNavigationBarButton()
        let navController = WooNavigationController(rootViewController: self)
        // Keeping the modal fullscreen on iPad like previous implementation.
        if UIDevice.current.userInterfaceIdiom == .pad {
            navController.modalPresentationStyle = .fullScreen
            navController.modalTransitionStyle = .crossDissolve
        }
        controller.present(navController, animated: true)
    }
}
