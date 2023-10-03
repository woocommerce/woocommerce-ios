import Foundation

/// Navigates to the WPCOM password flow.
///
public struct NavigateToEnterWPCOMPassword: NavigationCommand {
    private let loginFields: LoginFields

    public init(loginFields: LoginFields) {
        self.loginFields = loginFields
    }
    public func execute(from: UIViewController?) {
        presentUsernameAndPasswordView(navigationController: (from as? UINavigationController) ?? from?.navigationController, loginFields: loginFields)
    }
}

private extension NavigateToEnterWPCOMPassword {
    func presentUsernameAndPasswordView(navigationController: UINavigationController?, loginFields: LoginFields) {
        guard let vc = PasswordViewController.instantiate(from: .password) else {
            WPAuthenticatorLogError("Failed to navigate to PasswordViewController from GetStartedViewController")
            return
        }

        vc.loginFields = loginFields
//        vc.dismissBlock = dismissBlock
//        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
    }
}
