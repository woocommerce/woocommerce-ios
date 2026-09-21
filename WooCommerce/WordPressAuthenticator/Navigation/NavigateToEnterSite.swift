import Foundation

/// Navigates to the unified site address login flow.
///
public struct NavigateToEnterSite: NavigationCommand {
    private let loginFields: LoginFields?
    private let autoSubmitsPrefilledSiteAddress: Bool
    private let trackedFlow: AuthenticatorAnalyticsTracker.Flow?

    /// - Parameters:
    ///   - loginFields: When provided, its `siteAddress` pre-fills the site-address field.
    ///   - autoSubmitsPrefilledSiteAddress: When `true`, the screen submits the pre-filled
    ///     site address once, on first appearance, so the caller can hand the merchant
    ///     straight to the next login step.
    ///   - trackedFlow: When provided, the site-address screen tracks its step event
    ///     under this flow instead of the default `.loginWithSiteAddress`.
    public init(loginFields: LoginFields? = nil,
                autoSubmitsPrefilledSiteAddress: Bool = false,
                trackedFlow: AuthenticatorAnalyticsTracker.Flow? = nil) {
        self.loginFields = loginFields
        self.autoSubmitsPrefilledSiteAddress = autoSubmitsPrefilledSiteAddress
        self.trackedFlow = trackedFlow
    }

    public func execute(from: UIViewController?) {
        let navigationController = (from as? UINavigationController) ?? from?.navigationController
        presentUnifiedSiteAddressView(navigationController: navigationController)
    }
}

private extension NavigateToEnterSite {
    func presentUnifiedSiteAddressView(navigationController: UINavigationController?) {
        guard let vc = SiteAddressViewController.instantiate(from: .siteAddress) else {
            WPAuthenticatorLogError("Failed to navigate from LoginViewController to SiteAddressViewController")
            return
        }

        if let loginFields {
            vc.loginFields = loginFields
        }
        vc.autoSubmitsPrefilledSiteAddress = autoSubmitsPrefilledSiteAddress
        vc.trackedFlow = trackedFlow

        navigationController?.pushViewController(vc, animated: true)
    }
}
