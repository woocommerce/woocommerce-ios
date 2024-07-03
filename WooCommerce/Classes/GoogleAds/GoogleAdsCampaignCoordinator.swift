import Foundation
import Yosemite

/// Reusable coordinator to handle Google Ads campaigns.
///
final class GoogleAdsCampaignCoordinator: Coordinator {
    let navigationController: UINavigationController

    private let siteID: Int64
    private let siteAdminURL: String

    private let hasGoogleAdsCampaigns: Bool
    private let shouldAuthenticateAdminPage: Bool

    init(siteID: Int64,
         siteAdminURL: String,
         hasGoogleAdsCampaigns: Bool,
         shouldAuthenticateAdminPage: Bool,
         navigationController: UINavigationController) {
        self.siteID = siteID
        self.siteAdminURL = siteAdminURL
        self.shouldAuthenticateAdminPage = shouldAuthenticateAdminPage
        self.hasGoogleAdsCampaigns = hasGoogleAdsCampaigns
        self.navigationController = navigationController
    }

    func start() {
        guard let url = createGoogleAdsCampaignURL() else {
            return
        }
        let controller = createCampaignViewController(with: url)
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissCampaignView))
        navigationController.present(UINavigationController(rootViewController: controller), animated: true)
    }
}

// MARK: - Private helpers
//
private extension GoogleAdsCampaignCoordinator {
    @objc func dismissCampaignView() {
        navigationController.dismiss(animated: true)
    }

    func createCampaignViewController(with url: URL) -> UIViewController {
        let redirectHandler: (URL) -> Void = { [weak self] newURL in
            if newURL != url {
                self?.checkIfCampaignCreationSucceeded(url: newURL)
            }
        }
        if shouldAuthenticateAdminPage {
            let viewModel = DefaultAuthenticatedWebViewModel(
                title: Localization.googleForWooCommerce,
                initialURL: url,
                redirectHandler: redirectHandler
            )
            return AuthenticatedWebViewController(viewModel: viewModel)
        } else {
            let controller = WebViewHostingController(url: url, redirectHandler: redirectHandler)
            controller.title = Localization.googleForWooCommerce
            return controller
        }
    }

    func checkIfCampaignCreationSucceeded(url: URL) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        let queryItems = components?.queryItems
        let creationSucceeded = queryItems?.first(where: {
            $0.name == Constants.campaignParam &&
            $0.value == Constants.savedValue
        }) != nil
        if creationSucceeded {
            // dismisses the web view
            navigationController.dismiss(animated: true)

            // TODO: show success bottom sheet
            DDLogDebug("🎉 Google Ads campaign creation success")
        }
    }

    func createGoogleAdsCampaignURL() -> URL? {
        let path: String = {
            if hasGoogleAdsCampaigns {
                Constants.campaignDashboardPath
            } else {
                Constants.campaignCreationPath
            }
        }()
        return URL(string: siteAdminURL.appending(path))
    }
}


private extension GoogleAdsCampaignCoordinator {
    enum Constants {
        static let campaignDashboardPath = "admin.php?page=wc-admin&path=%2Fgoogle%2Fdashboard"
        static let campaignCreationPath = "admin.php?page=wc-admin&path=%2Fgoogle%2Fdashboard&subpath=%2Fcampaigns%2Fcreate"
        static let campaignParam = "campaign"
        static let savedValue = "saved"
    }

    enum Localization {
        static let googleForWooCommerce = NSLocalizedString(
            "googleAdsCampaignCoordinator.googleForWooCommerce",
            value: "Google for WooCommerce",
            comment: "Title of the Google Ads campaign view"
        )
    }
}
