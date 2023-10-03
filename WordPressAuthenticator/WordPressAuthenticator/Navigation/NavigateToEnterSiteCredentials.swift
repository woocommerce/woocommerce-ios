import Foundation

/// Navigates to the wp-admin site credentials flow.
///
public struct NavigateToEnterSiteCredentials: NavigationCommand {
    private let loginFields: LoginFields

    public init(loginFields: LoginFields) {
        self.loginFields = loginFields
    }
    public func execute(from: UIViewController?) {
        presentUsernameAndPasswordView(navigationController: (from as? UINavigationController) ?? from?.navigationController, loginFields: loginFields)
    }
}

private extension NavigateToEnterSiteCredentials {
    func presentUsernameAndPasswordView(navigationController: UINavigationController?, loginFields: LoginFields) {
        guard let vc = SiteCredentialsViewController.instantiate(from: .siteAddress) else {
            WPAuthenticatorLogError("Failed to navigate to SiteCredentialsViewController")
            return
        }

        vc.loginFields = loginFields
//        vc.dismissBlock = dismissBlock
//        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
    }
}
