import UIKit
import Yosemite

/// Configuration and actions for an ULErrorViewController,
/// modelling an error when WooCommerce is not installed or activated.
final class NoWooErrorViewModel: ULErrorViewModel {
    private let site: Site
    private let showsConnectedStores: Bool
    private let analytics: Analytics
    private let stores: StoresManager
    private let setupCompletionHandler: (Int64) -> Void

    private var storePickerCoordinator: StorePickerCoordinator?

    init(site: Site,
         showsConnectedStores: Bool,
         analytics: Analytics = ServiceLocator.analytics,
         stores: StoresManager = ServiceLocator.stores,
         onSetupCompletion: @escaping (Int64) -> Void) {
        self.site = site
        self.title = site.name
        self.showsConnectedStores = showsConnectedStores
        self.analytics = analytics
        self.stores = stores
        self.setupCompletionHandler = onSetupCompletion
    }

    // MARK: - Data and configuration
    let title: String?

    let image: UIImage = .noStoreImage

    var text: NSAttributedString {
        let font: UIFont = .body
        let boldFont: UIFont = font.bold

        let boldSiteAddress = NSAttributedString(string: site.url.trimHTTPScheme(),
                                                 attributes: [.font: boldFont])
        let message = NSMutableAttributedString(string: Localization.errorMessage)

        message.replaceFirstOccurrence(of: "%@", with: boldSiteAddress)

        return message
    }

    var isAuxiliaryButtonHidden: Bool { !showsConnectedStores }

    let auxiliaryButtonTitle = Localization.seeConnectedStores

    let primaryButtonTitle = Localization.primaryButtonTitle

    var isPrimaryButtonHidden: Bool {
        // Exclude simple sites and JCP sites - the web installation flow doesn't look great on these.
        !site.isJetpackConnected || !site.isJetpackThePluginInstalled
    }

    let secondaryButtonTitle = Localization.secondaryButtonTitle

    // MARK: - Actions
    func didTapPrimaryButton(in viewController: UIViewController?) {
        analytics.track(.loginWooCommerceSetupButtonTapped)
        guard let viewController = viewController else {
            return
        }
        let viewModel = WooSetupWebViewModel(siteURL: site.url, onCompletion: { [weak self] in
            guard let self = self else { return }
            viewController.navigationController?.popViewController(animated: true)
            self.showInProgressView(in: viewController)
            self.handleSetupCompletion(in: viewController)
        }, onDismiss: {
            viewController.navigationController?.popViewController(animated: true)
        })
        let setupViewController = AuthenticatedWebViewController(viewModel: viewModel)
        viewController.navigationController?.show(setupViewController, sender: nil)
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        // Log out and pop
        stores.deauthenticate()
        viewController?.navigationController?.popToRootViewController(animated: true)
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        guard let navigationController = viewController?.navigationController else {
            return
        }

        storePickerCoordinator = StorePickerCoordinator(navigationController, config: .listStores)
        storePickerCoordinator?.start()
    }

    func viewDidLoad(_ viewController: UIViewController?) {
        analytics.track(.loginWooCommerceErrorShown)
    }
}

// MARK: - Private helpers
private extension NoWooErrorViewModel {
    func handleSetupCompletion(in viewController: UIViewController, retryCount: Int = 0) {
        let action = AccountAction.synchronizeSites(selectedSiteID: site.siteID) { [weak self] _ in
            guard let self = self else { return }

            let matcher = ULAccountMatcher()
            matcher.refreshStoredSites()
            guard let site = matcher.matchedSite(originalURL: self.site.url),
                  site.isWooCommerceActive else {
                if retryCount < 2 {
                    // delays for 2 seconds to buy some time for the data to be synced
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                        self?.handleSetupCompletion(in: viewController, retryCount: retryCount + 1)
                    }
                    return
                }
                // dismisses the in-progress view
                viewController.navigationController?.dismiss(animated: true)
                return self.showSetupErrorNotice(in: viewController)
            }
            // dismisses the in-progress view
            viewController.navigationController?.dismiss(animated: true)
            self.setupCompletionHandler(site.siteID)
        }
        stores.dispatch(action)
    }

    func showInProgressView(in viewController: UIViewController) {
        let viewProperties = InProgressViewProperties(title: Localization.verifyingInstallation, message: "")
        let inProgressViewController = InProgressViewController(viewProperties: viewProperties)
        inProgressViewController.modalPresentationStyle = .overCurrentContext

        viewController.navigationController?.present(inProgressViewController, animated: true, completion: nil)
    }

    func showSetupErrorNotice(in viewController: UIViewController) {
        let message = Localization.setupErrorMessage
        let notice = Notice(title: message, feedbackType: .error)
        let noticePresenter = DefaultNoticePresenter()
        noticePresenter.presentingViewController = viewController
        noticePresenter.enqueue(notice: notice)
    }
}

// MARK: - Private data structures
private extension NoWooErrorViewModel {
    enum Localization {
        static let errorMessage = NSLocalizedString("It looks like %@ is not a WooCommerce site.",
                                                    comment: "Message explaining that the site entered doesn't have WooCommerce installed or activated. "
                                                        + "Reads like 'It looks like awebsite.com is not a WooCommerce site.")

        static let seeConnectedStores = NSLocalizedString("See Connected Stores",
                                                          comment: "Action button linking to a list of connected stores. "
                                                          + "Presented when logging in with a store address that does not have WooCommerce.")

        static let primaryButtonTitle = NSLocalizedString("Install WooCommerce",
                                                          comment: "Action button for installing WooCommerce."
                                                          + "Presented when logging in with a site address that does not have WooCommerce")

        static let secondaryButtonTitle = NSLocalizedString("Log In With Another Account",
                                                            comment: "Action button that will restart the login flow."
                                                            + "Presented when logging in with a site address that does not have WooCommerce")

        static let verifyingInstallation = NSLocalizedString("Verifying installation...",
                                                             comment: "Message displayed when checking whether a site has successfully installed WooCommerce")
        static let setupErrorMessage = NSLocalizedString("Cannot verify your site's WooCommerce installation.",
                                                         comment: "Error message displayed when failed to check for WooCommerce in a site.")
    }
}
