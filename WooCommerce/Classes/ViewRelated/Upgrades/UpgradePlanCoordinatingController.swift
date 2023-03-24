import UIKit

/// Controls navigation for the free trial upgrade plan flow. Meant to be presented modally
///
final class UpgradePlanCoordinatingController: WooNavigationController {

    /// Current Site ID.
    ///
    private let siteID: Int64

    /// Source of the action.
    ///
    private let source: WooAnalyticsEvent.FreeTrial.Source

    /// Analytics provider.
    ///
    private let analytics: Analytics

    /// Closure to be invoked when the plan is successfully upgraded.
    ///
    private let onSuccess: (() -> ())?

    init(siteID: Int64,
         source: WooAnalyticsEvent.FreeTrial.Source,
         analytics: Analytics = ServiceLocator.analytics,
         onSuccess: (() -> ())? = nil) {
        self.siteID = siteID
        self.source = source
        self.analytics = analytics
        self.onSuccess = onSuccess
        super.init(nibName: nil, bundle: nil)
        startNavigation()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Shows a web view for the merchant to update their site plan.
    ///
    private func startNavigation() {
        analytics.track(event: .FreeTrial.freeTrialUpgradeNowTapped(source: source))

        guard let upgradeURL = Constants.upgradeURL(siteID: siteID) else { return }
        let viewModel = DefaultAuthenticatedWebViewModel(title: Localization.upgradeNow,
                                                         initialURL: upgradeURL,
                                                         urlToTriggerExit: Constants.exitTrigger) { [weak self] in
            self?.exitUpgradeFreeTrialFlowAfterUpgrade()
        }

        isModalInPresentation = true
        let webViewController = AuthenticatedWebViewController(viewModel: viewModel)
        webViewController.navigationItem.leftBarButtonItem =  UIBarButtonItem(barButtonSystemItem: .cancel,
                                                                              target: self,
                                                                              action: #selector(exitUpgradeFreeTrialFlow))
        setViewControllers([webViewController], animated: false)
    }

    /// Dismisses the upgrade now web view after the merchants successfully updates their plan.
    ///
    func exitUpgradeFreeTrialFlowAfterUpgrade() {
        onSuccess?()
        dismiss(animated: true)

        analytics.track(event: .FreeTrial.planUpgradeSuccess(source: source))
    }

    /// Dismisses the upgrade now web view when the user abandons the flow.
    ///
    @objc func exitUpgradeFreeTrialFlow() {
        dismiss(animated: true)

        analytics.track(event: .FreeTrial.planUpgradeAbandoned(source: source))
    }
}

private extension UpgradePlanCoordinatingController {
    enum Constants {

        /// URL Path invoked when a site is upgrade from a free trial.
        ///
        static let exitTrigger = "my-plan/trial-upgraded"

        /// URL that allows merchants to upgrade their eCommerce plan.
        ///
        static func upgradeURL(siteID: Int64) -> URL? {
            URL(string: "https://wordpress.com/plans/\(siteID)")
        }
    }

    enum Localization {
        static let upgradeNow = NSLocalizedString("Upgrade Now", comment: "Title for the WebView when upgrading a free trial plan")
    }
}
