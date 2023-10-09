import Foundation

/// Navigates to the wp-admin site credentials flow.
///
public struct NavigateToEnterSiteCredentials: NavigationCommand {
    private let loginFields: LoginFields
    private let onDismiss: () -> Void

    public init(loginFields: LoginFields, onDismiss: (() -> Void)?) {
        self.loginFields = loginFields
        self.onDismiss = onDismiss ?? {}
    }
    public func execute(from: UIViewController?) {
        let navigationController = (from as? UINavigationController) ?? from?.navigationController
        presentSiteCredentialsView(navigationController: navigationController,
                                   loginFields: loginFields,
                                   onDismiss: onDismiss)
    }
}

private extension NavigateToEnterSiteCredentials {
    func presentSiteCredentialsView(navigationController: UINavigationController?, loginFields: LoginFields, onDismiss: @escaping () -> Void) {
        guard let controller = SiteCredentialsViewController.instantiate(from: .siteAddress) else {
            WPAuthenticatorLogError("Failed to navigate to SiteCredentialsViewController")
            return
        }

        controller.loginFields = loginFields
        controller.dismissBlock = { _ in
            onDismiss()
        }

        navigationController?.pushViewController(controller, animated: true)
    }
}
