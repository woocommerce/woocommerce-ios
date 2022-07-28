import Foundation

/// Navigates to the unified "Continue with WordPress.com" flow.
///
public struct NavigateToEnterAccount: NavigationCommand {
    public init() {}
    public func execute(from: UIViewController?) {
        continueWithDotCom(navigationController: from?.navigationController)
    }
}

private extension NavigateToEnterAccount {
    private func continueWithDotCom(navigationController: UINavigationController?) {
        guard let vc = GetStartedViewController.instantiate(from: .getStarted) else {
            DDLogError("Failed to navigate from LoginPrologueViewController to GetStartedViewController")
            return
        }
        vc.source = .wpCom

        navigationController?.pushViewController(vc, animated: true)
    }
}
