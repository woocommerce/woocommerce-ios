import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// Reusable coordinator to handle Google Ads campaigns.
///
final class GoogleAdsCampaignCoordinator: NSObject, Coordinator {
    let navigationController: UINavigationController

    private let siteID: Int64
    private let siteAdminURL: String
    private let source: WooAnalyticsEvent.GoogleAds.Source

    private let shouldStartCampaignCreation: Bool
    private let shouldAuthenticateAdminPage: Bool
    private var bottomSheetPresenter: BottomSheetPresenter?

    private let analytics: Analytics

    private let onCompletion: () -> Void

    private var hasTrackedStartEvent = false

    init(siteID: Int64,
         siteAdminURL: String,
         source: WooAnalyticsEvent.GoogleAds.Source,
         shouldStartCampaignCreation: Bool,
         shouldAuthenticateAdminPage: Bool,
         navigationController: UINavigationController,
         analytics: Analytics = ServiceLocator.analytics,
         onCompletion: @escaping () -> Void) {
        self.siteID = siteID
        self.siteAdminURL = siteAdminURL
        self.source = source
        self.shouldAuthenticateAdminPage = shouldAuthenticateAdminPage
        self.shouldStartCampaignCreation = shouldStartCampaignCreation
        self.navigationController = navigationController
        self.analytics = analytics
        self.onCompletion = onCompletion
    }

    func start() {
        guard let url = createGoogleAdsCampaignURL() else {
            return
        }
        let controller = createCampaignViewController(with: url)
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissCampaignView))

        let parentController = UINavigationController(rootViewController: controller)
        navigationController.present(parentController, animated: true)
        parentController.presentationController?.delegate = self
    }
}

extension GoogleAdsCampaignCoordinator: UIAdaptivePresentationControllerDelegate {
    // Triggered when swiping to dismiss the view.
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onCompletion()
        analytics.track(event: .GoogleAds.flowCanceled(source: source))
    }
}

// MARK: - Private helpers
//
private extension GoogleAdsCampaignCoordinator {
    @objc func dismissCampaignView() {
        onCompletion()
        navigationController.dismiss(animated: true)
        analytics.track(event: .GoogleAds.flowCanceled(source: source))
    }

    func createCampaignViewController(with url: URL) -> UIViewController {
        let pageLoadHandler: (URL) -> Void = { [weak self] newURL in
            guard let self else { return }
            if newURL == url, !hasTrackedStartEvent {
                ServiceLocator.analytics.track(event: .GoogleAds.flowStarted(source: source))
                hasTrackedStartEvent = true
            }
        }

        let redirectHandler: (URL) -> Void = { [weak self] newURL in
            guard let self else { return }
            if newURL != url {
                checkIfCampaignCreationSucceeded(url: newURL)
            }
        }

        let errorHandler: (Error) -> Void = { [weak self] error in
            guard let self else { return }
            analytics.track(event: .GoogleAds.flowError(source: source, error: error))
        }

        if shouldAuthenticateAdminPage {
            let viewModel = DefaultAuthenticatedWebViewModel(
                title: Localization.googleForWooCommerce,
                initialURL: url,
                pageLoadHandler: pageLoadHandler,
                redirectHandler: redirectHandler,
                errorHandler: errorHandler
            )
            return AuthenticatedWebViewController(viewModel: viewModel)
        } else {
            let controller = WebViewHostingController(url: url,
                                                      pageLoadHandler: pageLoadHandler,
                                                      redirectHandler: redirectHandler,
                                                      errorHandler: errorHandler)
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
            analytics.track(event: .GoogleAds.campaignCreationSuccess(source: source))

            // dismisses the web view
            navigationController.dismiss(animated: true) { [self] in
                showSuccessView()
            }
            onCompletion()
            DDLogDebug("🎉 Google Ads campaign creation success")
        }
    }

    func createGoogleAdsCampaignURL() -> URL? {
        let path: String = {
            if shouldStartCampaignCreation {
                Constants.campaignCreationPath
            } else {
                Constants.campaignDashboardPath
            }
        }()
        return URL(string: siteAdminURL.appending(path))
    }

    func showSuccessView() {
        bottomSheetPresenter = buildBottomSheetPresenter()
        let controller = CelebrationHostingController(
            title: Localization.successTitle,
            subtitle: Localization.successSubtitle,
            closeButtonTitle: Localization.successCTA,
            image: .blazeSuccessImage,
            onTappingDone: { [weak self] in
            self?.bottomSheetPresenter?.dismiss()
            self?.bottomSheetPresenter = nil
        })
        bottomSheetPresenter?.present(controller, from: navigationController)
    }

    func buildBottomSheetPresenter() -> BottomSheetPresenter {
        BottomSheetPresenter(configure: { bottomSheet in
            var sheet = bottomSheet
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.prefersGrabberVisible = true
            sheet.detents = [.medium()]
        })
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
        static let successTitle = NSLocalizedString(
            "googleAdsCampaignCoordinator.successTitle",
            value: "Ready to Go!",
            comment: "Title of the celebration view when a Google ads campaign is successfully created."
        )
        static let successSubtitle = NSLocalizedString(
            "googleAdsCampaignCoordinator.successSubtitle",
            value: "Your new campaign has been created. Exciting times ahead for your sales!",
            comment: "Subtitle of the celebration view when a Google Ads campaign is successfully created."
        )
        static let successCTA = NSLocalizedString(
            "googleAdsCampaignCoordinator.successCTA",
            value: "Done",
            comment: "Button to dismiss the celebration view when a Google Ads campaign is successfully created."
        )
    }
}
