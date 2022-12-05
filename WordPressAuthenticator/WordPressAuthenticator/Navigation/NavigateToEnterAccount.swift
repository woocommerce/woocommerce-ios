import Foundation

/// Navigates to the unified "Continue with WordPress.com" flow.
///
public struct NavigateToEnterAccount: NavigationCommand {
    private let signInSource: SignInSource

    public init(signInSource: SignInSource) {
        self.signInSource = signInSource
    }

    public func execute(from: UIViewController?) {
        continueWithDotCom(navigationController: from?.navigationController)
    }
}

private extension NavigateToEnterAccount {
    private func continueWithDotCom(navigationController: UINavigationController?) {
        guard let vc = GetStartedViewController.instantiate(from: .getStarted) else {
            WPAuthenticatorLogError("Failed to navigate from LoginPrologueViewController to GetStartedViewController")
            return
        }
        vc.source = signInSource

        navigationController?.pushViewController(vc, animated: true)
    }
}
