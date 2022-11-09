import Combine
import UIKit
import Yosemite
import protocol Storage.StorageManagerType

/// Coordinates navigation for store creation flow, with the assumption that the app is already authenticated with a WPCOM user.
final class StoreCreationCoordinator: Coordinator {
    /// Navigation source to store creation.
    enum Source {
        /// Initiated from the logged-out state.
        case loggedOut(source: LoggedOutStoreCreationCoordinator.Source)
        /// Initiated from the store picker in logged-in state.
        case storePicker
    }

    let navigationController: UINavigationController

    @Published private var possibleSiteURLsFromStoreCreation: Set<String> = []
    private var possibleSiteURLsFromStoreCreationSubscription: AnyCancellable?

    private let analytics: Analytics
    private let source: Source
    private let storePickerViewModel: StorePickerViewModel
    private let switchStoreUseCase: SwitchStoreUseCaseProtocol

    init(source: Source,
         navigationController: UINavigationController,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.source = source
        self.navigationController = navigationController
        // Passing the `standard` configuration to include sites without WooCommerce (`isWooCommerceActive = false`).
        self.storePickerViewModel = .init(configuration: .standard,
                                          stores: stores,
                                          storageManager: storageManager,
                                          analytics: analytics)
        self.switchStoreUseCase = SwitchStoreUseCase(stores: stores, storageManager: storageManager)
        self.analytics = analytics
    }

    func start() {
        observeSiteURLsFromStoreCreation()

        let viewModel = StoreCreationWebViewModel { [weak self] result in
            self?.handleStoreCreationResult(result)
        }
        possibleSiteURLsFromStoreCreation = []
        let webViewController = AuthenticatedWebViewController(viewModel: viewModel)
        webViewController.addCloseNavigationBarButton(target: self, action: #selector(handleStoreCreationCloseAction))
        let webNavigationController = WooNavigationController(rootViewController: webViewController)
        // Disables interactive dismissal of the store creation modal.
        webNavigationController.isModalInPresentation = true

        // If the navigation controller is already presenting another view, the view needs to be dismissed before store
        // creation view can be presented.
        if navigationController.presentedViewController != nil {
            navigationController.dismiss(animated: true) { [weak self] in
                self?.navigationController.present(webNavigationController, animated: true)
            }
        } else {
            navigationController.present(webNavigationController, animated: true)
        }
    }
}

private extension StoreCreationCoordinator {
    func observeSiteURLsFromStoreCreation() {
        possibleSiteURLsFromStoreCreationSubscription = $possibleSiteURLsFromStoreCreation
            .filter { $0.isEmpty == false }
            .removeDuplicates()
            // There are usually three URLs in the webview that return a site URL - two with `*.wordpress.com` and the other the final URL.
            .debounce(for: .seconds(5), scheduler: DispatchQueue.main)
            .asyncMap { [weak self] possibleSiteURLs -> Site? in
                // Waits for 5 seconds before syncing sites every time.
                try await Task.sleep(nanoseconds: 5_000_000_000)
                return try await self?.syncSites(forSiteThatMatchesPossibleURLs: possibleSiteURLs)
            }
            // Retries 10 times with 5 seconds pause in between to wait for the newly created site to be available as a Jetpack site
            // in the WPCOM `/me/sites` response.
            .retry(10)
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] site in
                guard let self, let site else { return }
                self.continueWithSelectedSite(site: site)
            }
    }

    @objc func handleStoreCreationCloseAction() {
        analytics.track(event: .StoreCreation.siteCreationDismissed(source: source.analyticsValue))
        showDiscardChangesAlert()
    }

    func handleStoreCreationResult(_ result: Result<String, Error>) {
        switch result {
        case .success(let siteURL):
            // There could be multiple site URLs from the completion URL in the webview, and only one
            // of them matches the final site URL from WPCOM `/me/sites` endpoint.
            possibleSiteURLsFromStoreCreation.insert(siteURL)
        case .failure(let error):
            analytics.track(event: .StoreCreation.siteCreationFailed(source: source.analyticsValue, error: error))
            DDLogError("Store creation error: \(error)")
        }
    }

    @MainActor
    func syncSites(forSiteThatMatchesPossibleURLs possibleURLs: Set<String>) async throws -> Site {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            storePickerViewModel.refreshSites(currentlySelectedSiteID: nil) { [weak self] in
                guard let self else {
                    return continuation.resume(throwing: StoreCreationCoordinatorError.selfDeallocated)
                }
                // The newly created site often has `isJetpackThePluginInstalled=false` initially,
                // which results in a JCP site.
                // In this case, we want to retry sites syncing.
                guard let site = self.storePickerViewModel.site(thatMatchesPossibleURLs: possibleURLs) else {
                    return continuation.resume(throwing: StoreCreationError.newSiteUnavailable)
                }
                guard site.isJetpackConnected && site.isJetpackThePluginInstalled else {
                    return continuation.resume(throwing: StoreCreationError.newSiteIsNotJetpackSite)
                }
                continuation.resume(returning: site)
            }
        }
    }

    func continueWithSelectedSite(site: Site) {
        analytics.track(event: .StoreCreation.siteCreated(source: source.analyticsValue, siteURL: site.url))
        switchStoreUseCase.switchStore(with: site.siteID) { [weak self] siteChanged in
            guard let self else { return }

            // Shows `My store` tab by default.
            MainTabBarController.switchToMyStoreTab(animated: true)

            self.navigationController.dismiss(animated: true)
        }
    }

    func showDiscardChangesAlert() {
        let alert = UIAlertController(title: Localization.DiscardChangesAlert.title,
                                      message: Localization.DiscardChangesAlert.message,
                                      preferredStyle: .alert)
        alert.view.tintColor = .text

        alert.addDestructiveActionWithTitle(Localization.DiscardChangesAlert.confirmActionTitle) { [weak self] _ in
            self?.navigationController.dismiss(animated: true)
        }

        alert.addCancelActionWithTitle(Localization.DiscardChangesAlert.cancelActionTitle) { _ in }

        // Presents the alert with the presented webview.
        navigationController.presentedViewController?.present(alert, animated: true)
    }
}

private extension StoreCreationCoordinator {
    enum StoreCreationCoordinatorError: Error {
        case selfDeallocated
    }

    enum Localization {
        enum DiscardChangesAlert {
            static let title = NSLocalizedString("Do you want to leave?",
                                                 comment: "Title of the alert when the user dismisses the store creation flow.")
            static let message = NSLocalizedString("You will lose all your store information.",
                                                   comment: "Message of the alert when the user dismisses the store creation flow.")
            static let confirmActionTitle = NSLocalizedString("Confirm and leave",
                                                              comment: "Button title Discard Changes in Discard Changes Action Sheet")
            static let cancelActionTitle = NSLocalizedString("Cancel",
                                                             comment: "Button title Cancel in Discard Changes Action Sheet")
        }
    }
}

private extension StoreCreationCoordinator.Source {
    var analyticsValue: WooAnalyticsEvent.StoreCreation.Source {
        switch self {
        case .storePicker:
            return .storePicker
        case .loggedOut(let source):
            switch source {
            case .prologue:
                return .loginPrologue
            case .loginEmailError:
                return .loginEmailError
            }
        }
    }
}
