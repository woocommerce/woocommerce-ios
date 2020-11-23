import Foundation

public struct NavigateToEnterAccount: NavigationCommand {
    public init() {}
    public func execute(with: UINavigationController?) {
        print("Off we go to Enter a New WordPress.com account")
        continueWithDotCom(navigationController: with)
    }
}


private extension NavigateToEnterAccount {
    /// Unified "Continue with WordPress.com" prologue button action.
    ///
    private func continueWithDotCom(navigationController: UINavigationController?) {
        guard let vc = GetStartedViewController.instantiate(from: .getStarted) else {
            DDLogError("Failed to navigate from LoginPrologueViewController to GetStartedViewController")
            return
        }

        navigationController?.pushViewController(vc, animated: true)
    }
}
