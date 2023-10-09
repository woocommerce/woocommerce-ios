import Foundation

/// Navigates to the WPCOM password flow.
///
public struct NavigateToEnterWPCOMPassword: NavigationCommand {
    private let loginFields: LoginFields
    private let onDismiss: () -> Void

    public init(loginFields: LoginFields, onDismiss: (() -> Void)?) {
        self.loginFields = loginFields
        self.onDismiss = onDismiss ?? {}
    }
    public func execute(from: UIViewController?) {
        let navigationController = (from as? UINavigationController) ?? from?.navigationController
        presentPasswordView(navigationController: navigationController,
                            loginFields: loginFields,
                            onDismiss: onDismiss)
    }
}

private extension NavigateToEnterWPCOMPassword {
    func presentPasswordView(navigationController: UINavigationController?, loginFields: LoginFields, onDismiss: @escaping () -> Void) {
        guard let controller = PasswordViewController.instantiate(from: .password) else {
            WPAuthenticatorLogError("Failed to navigate to PasswordViewController from GetStartedViewController")
            return
        }

        controller.loginFields = loginFields
        controller.dismissBlock = { _ in
            onDismiss()
        }

        navigationController?.pushViewController(controller, animated: true)
    }
}
