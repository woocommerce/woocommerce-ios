import Combine
import UIKit
import Yosemite
import enum Networking.SiteCreationFlow
import protocol Experiments.FeatureFlagService
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics
import struct WooFoundation.WooAnalyticsEvent

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

    // MARK: - Store creation M1

    @Published private var possibleSiteURLsFromStoreCreation: Set<String> = []
    private var possibleSiteURLsFromStoreCreationSubscription: AnyCancellable?

    private var jetpackSiteSubscription: AnyCancellable?

    private let stores: StoresManager
    private let analytics: Analytics
    private let source: Source
    private let storePickerViewModel: StorePickerViewModel
    private let switchStoreUseCase: SwitchStoreUseCaseProtocol
    private let storeSwitcher: StoreCreationStoreSwitchScheduler
    private let featureFlagService: FeatureFlagService

    private weak var storeCreationProgressViewModel: StoreCreationProgressViewModel?
    private var statusChecker: StoreCreationStatusChecker?

    /// Created store with updated information after Jetpack sync completes.
    private var createdStore: Site?

    init(source: Source,
         navigationController: UINavigationController,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         pushNotesManager: PushNotesManager = ServiceLocator.pushNotesManager) {
        self.source = source
        self.navigationController = navigationController
        // Passing the `standard` configuration to include sites without WooCommerce (`isWooCommerceActive = false`).
        self.storePickerViewModel = .init(configuration: .standard,
                                          stores: stores,
                                          storageManager: storageManager,
                                          analytics: analytics)
        self.switchStoreUseCase = SwitchStoreUseCase(stores: stores, storageManager: storageManager)
        self.storeSwitcher = DefaultStoreCreationStoreSwitchScheduler()
        self.stores = stores
        self.analytics = analytics
        self.featureFlagService = featureFlagService
    }

    func start() {
        analytics.track(event: .StoreCreation.siteCreationFlowStarted(source: source.analyticsValue))
        let storeCreationNavigationController = WooNavigationController()
        startStoreCreation(from: storeCreationNavigationController)
        presentStoreCreation(viewController: storeCreationNavigationController)
    }
}

private extension StoreCreationCoordinator {

    func startStoreCreation(from navigationController: UINavigationController) {
        // Disables interactive dismissal of the store creation modal.
        navigationController.isModalInPresentation = true

        navigationController.isNavigationBarHidden = true

        showFreeTrialSummaryView(from: navigationController, storeName: WooConstants.defaultStoreName)
    }

    func showProfilerFlow(storeName: String, siteID: Int64, from navigationController: UINavigationController) {
        navigationController.isNavigationBarHidden = false
        let viewModel = StoreCreationProfilerQuestionContainerViewModel(siteID: siteID,
                                                                        storeName: storeName,
                                                                        onCompletion: { [weak self] in
            guard let self else { return }
            if let site = self.createdStore {
                self.continueWithSelectedSite(site: site)
            } else {
                self.analytics.track(event: .StoreCreation.siteCreationStep(step: .storeInstallation))
                self.showInProgressView(from: navigationController)
            }
        },
                                                                        uploadAnswersUseCase: StoreCreationProfilerUploadAnswersUseCase(siteID: siteID))
        let controller = StoreCreationProfilerQuestionContainerHostingController(viewModel: viewModel,
                                                                                 onSupport: { [weak self] in
            self?.showSupport(from: navigationController)
        })
        navigationController.setViewControllers([controller], animated: true)
    }

    func presentStoreCreation(viewController: UIViewController) {
        // If the navigation controller is already presenting another view, the view needs to be dismissed before store
        // creation view can be presented.
        if navigationController.presentedViewController != nil {
            navigationController.dismiss(animated: true) { [weak self] in
                guard let self else { return }
                self.navigationController.present(viewController, animated: true)
            }
        } else {
            navigationController.present(viewController, animated: true)
        }
    }
}

// MARK: - Actions & Alerts
private extension StoreCreationCoordinator {

    func continueWithSelectedSite(site: Site) {
        switchStoreUseCase.switchStore(with: site.siteID) { [weak self] siteChanged in
            guard let self else { return }

            self.storeSwitcher.removePendingStoreSwitch()
            // Shows `My store` tab by default.
            MainTabBarController.switchToMyStoreTab(animated: true)

            self.navigationController.dismiss(animated: true)
        }
    }

    func showStoreCreationErrorAlert(from viewController: UIViewController) {
        let alertController = UIAlertController(title: Localization.StoreCreationErrorAlert.title,
                                                message: Localization.StoreCreationErrorAlert.message,
                                                preferredStyle: .alert)
        _ = alertController.addDestructiveActionWithTitle(Localization.StoreCreationErrorAlert.cancelActionTitle) { [weak self] _ in
            self?.navigationController.dismiss(animated: true)
        }
        _ = alertController.addDefaultActionWithTitle(Localization.StoreCreationErrorAlert.retryAction) { _ in }
        viewController.present(alertController, animated: true)
    }

    func showSupport(from navigationController: UINavigationController) {
        let sourceTag = "origin:store-creation"
        let supportForm = SupportFormHostingController(viewModel: .init(sourceTag: sourceTag))
        supportForm.show(from: navigationController)
    }
}

// MARK: - Store creation
private extension StoreCreationCoordinator {

    /// Presents the free trial summary view.
    /// After user confirmation proceeds to create a store with a free trial plan.
    ///
    func showFreeTrialSummaryView(from navigationController: UINavigationController,
                                  storeName: String) {
        let summaryViewController = FreeTrialSummaryHostingController(onClose: { [weak self] in
            guard let self else { return }
            self.analytics.track(event: .StoreCreation.siteCreationDismissed(source: self.source.analyticsValue, flow: .native, isFreeTrial: true))
            self.navigationController.dismiss(animated: true)
        }, onContinue: { [weak self] in
            guard let self else { return }
            self.analytics.track(event: .StoreCreation.siteCreationTryForFreeTapped())
            let result = await self.createFreeTrialStore(storeName: storeName)
            await MainActor.run {
                self.handleFreeTrialStoreCreation(from: navigationController, result: result)
            }
        })

        navigationController.pushViewController(summaryViewController, animated: true)
    }

    /// This method creates a free trial store async:
    /// - Create a simple site
    /// - Enable Free Trial on the site
    ///
    @MainActor
    func createFreeTrialStore(storeName: String) async -> Result<SiteCreationResult, SiteCreationError> {
        // Create store site
        let createStoreResult = await createStore(name: storeName, flow: .wooexpress)

        switch createStoreResult {
        case .success(let siteResult):

            // Enable Free trial on site
            let freeTrialResult = await enableFreeTrial(siteID: siteResult.siteID)
            switch freeTrialResult {
            case .success:
                return .success(siteResult)
            case .failure(let error):
                return .failure(SiteCreationError(remoteError: error))
            }

        case .failure(let error):
            return .failure(error)
        }
    }

    /// Handles the result from the async free trial store creation and navigates to the in-progress UI on success or show an alert on failure.
    /// While on the in-progress UI, it waits for Jetpack to be installed on the site.
    func handleFreeTrialStoreCreation(from navigationController: UINavigationController, result: Result<SiteCreationResult, SiteCreationError>) {
        switch result {
        case .success(let siteResult):
            storeSwitcher.savePendingStoreSwitch(siteID: siteResult.siteID, expectedStoreName: siteResult.name)
            showProfilerFlow(storeName: siteResult.name, siteID: siteResult.siteID, from: navigationController)

            // Wait for jetpack to be installed
            DDLogInfo("🟢 Free trial enabled on site. Waiting for jetpack to be installed...")
            Task { @MainActor in
                await waitForSiteToBecomeJetpackSite(from: navigationController, siteID: siteResult.siteID, expectedStoreName: siteResult.name)
                analytics.track(event: .StoreCreation.siteCreationRequestSuccess(
                    siteID: siteResult.siteID,
                    domainName: siteResult.siteSlug
                ))
            }

        case .failure(let error):
            showStoreCreationErrorAlert(from: navigationController.topmostPresentedViewController)
            analytics.track(event: .StoreCreation.siteCreationFailed(source: source.analyticsValue,
                                                                     error: error,
                                                                     flow: .native,
                                                                     isFreeTrial: true))
        }
    }

    @MainActor
    func createStore(name: String, flow: SiteCreationFlow) async -> Result<SiteCreationResult, SiteCreationError> {
        await withCheckedContinuation { continuation in
            stores.dispatch(SiteAction.createSite(name: name, flow: flow) { result in
                continuation.resume(returning: result)
            })
        }
    }

    /// Enables a free trial on a recently created store.
    ///
    @MainActor
    func enableFreeTrial(siteID: Int64) async -> Result<Void, Error> {
        await withCheckedContinuation { continuation in
            stores.dispatch(SiteAction.enableFreeTrial(siteID: siteID) { result in
                continuation.resume(returning: result)
            })
        }
    }

    func showInProgressView(from navigationController: UINavigationController) {
        let approxSecondsToWaitForNetworkRequest = 10.0
        let viewModel = StoreCreationProgressViewModel(estimatedTimePerProgress: Constants.jetpackCheckRetryInterval + approxSecondsToWaitForNetworkRequest)
        let storeCreationProgressView = StoreCreationProgressHostingViewController(viewModel: viewModel)
        navigationController.isNavigationBarHidden = true
        self.storeCreationProgressViewModel = viewModel
        navigationController.pushViewController(storeCreationProgressView, animated: true)
    }

    @MainActor
    func waitForSiteToBecomeJetpackSite(from navigationController: UINavigationController, siteID: Int64, expectedStoreName: String) async {
        /// Timestamp when we start observing times. Needed to track the store creating waiting duration.
        ///
        let waitingTimeStart = Date()

        let statusChecker = StoreCreationStatusChecker(isFreeTrialCreation: true, storeName: expectedStoreName, stores: stores)
        self.statusChecker = statusChecker
        let site: Site? = await withCheckedContinuation { continuation in
            jetpackSiteSubscription = statusChecker.waitForSiteToBeReady(siteID: siteID)
                .handleEvents(receiveCompletion: { [weak self] completion in
                    guard let self, case .failure = completion else {
                        return
                    }
                    self.storeCreationProgressViewModel?.incrementProgress()
                })
            // Retries 15 times with some seconds pause in between to wait for the newly created site to be available as a Jetpack/Woo site.
                .retry(15)
                .sink (receiveCompletion: { completion in
                    guard case .failure = completion else {
                        return
                    }
                    continuation.resume(returning: nil)
                }, receiveValue: { site in
                    continuation.resume(returning: site)
                })
        }
        handleCompletionStatus(siteID: siteID, site: site, waitingTimeStart: waitingTimeStart, expectedStoreName: expectedStoreName)
    }

    func handleCompletionStatus(siteID: Int64, site: Site?, waitingTimeStart: Date, expectedStoreName: String) {
        guard let site else {
            return showJetpackSiteTimeoutView { [weak self] in
                guard let self else { return }
                self.analytics.track(event: .StoreCreation.siteCreationTimeoutRetried())
                await self.waitForSiteToBecomeJetpackSite(from: self.navigationController, siteID: siteID, expectedStoreName: expectedStoreName)
            }
        }

        // Sometimes, as soon as the jetpack installation is done some properties like `name` and `isWordPressComStore` are outdated.
        // Track when a properties out of sync event occur, but only track it once.
        // https://github.com/woocommerce/woocommerce-ios/pull/9317#issuecomment-1488035433
        if !(site.isWordPressComStore && site.isWooCommerceActive && site.name == expectedStoreName) {
            DDLogInfo("🔵 Site available but properties are not yet in sync...")
            analytics.track(event: .StoreCreation.siteCreationPropertiesOutOfSync())
        }

        createdStore = site
        /// Show the dashboard immediately if the progress view is displayed
        /// or do nothing otherwise
        if let storeCreationProgressViewModel {
            storeCreationProgressViewModel.markAsComplete()
            continueWithSelectedSite(site: site)
        }
        trackSiteCreatedEvent(site: site, flow: .native, timeAtStart: waitingTimeStart)
    }

    func showSuccessView(from navigationController: UINavigationController, site: Site) {
        guard let url = URL(string: site.url) else {
            return continueWithSelectedSite(site: site)
        }
        let successView = StoreCreationSuccessHostingController(siteURL: url) { [weak self] in
            guard let self else { return }
            self.analytics.track(event: .StoreCreation.siteCreationManageStoreTapped())
            self.continueWithSelectedSite(site: site)
        } onPreviewSite: { [weak self] in
            self?.analytics.track(event: .StoreCreation.siteCreationSitePreviewed())
        }
        navigationController.pushViewController(successView, animated: true)
    }

    func showJetpackSiteTimeoutView(onRetry: @escaping () async -> Void) {
        guard (navigationController.topViewController is StoreCreationTimeoutHostingController) == false else {
            return
        }
        let controller = StoreCreationTimeoutHostingController(onRetry: onRetry)
        navigationController.isNavigationBarHidden = true
        // Make sure that nothing is presented on the view controller before showing the timeout screen
        navigationController.presentedViewController?.dismiss(animated: true) { [weak self] in
            self?.navigationController.pushViewController(controller, animated: true)
        }
        analytics.track(event: .StoreCreation.siteCreationTimedOut())
    }

    /// Tracks when a store has been successfully created.
    ///
    func trackSiteCreatedEvent(site: Site, flow: WooAnalyticsEvent.StoreCreation.Flow, timeAtStart: Date) {
        let waitingTime = "\(Date().timeIntervalSince(timeAtStart))"
        analytics.track(event: .StoreCreation.siteCreated(source: source.analyticsValue,
                                                          siteURL: site.url,
                                                          flow: flow,
                                                          isFreeTrial: true,
                                                          waitingTime: waitingTime))
    }
}

private extension StoreCreationCoordinator {
    enum StoreCreationCoordinatorError: Error {
        case selfDeallocated
    }

    enum Localization {
        enum DiscardChangesAlert {
            static let title = NSLocalizedString("Do you want to leave?",
                                                 comment: "Title of the alert when the user dismisses the store creation profiler flow.")
            static let message = NSLocalizedString("You will lose all your store information.",
                                                   comment: "Message of the alert when the user dismisses the store creation profiler flow.")
            static let confirmActionTitle = NSLocalizedString("Confirm and leave",
                                                              comment: "Button to confirm the dismissal of  the store creation profiler flow")
            static let cancelActionTitle = NSLocalizedString("Cancel",
                                                             comment: "Button to dismiss the alert on the store creation profiler flow")
        }

        enum StoreCreationErrorAlert {
            static let title = NSLocalizedString(
                "Oops! We've hit a snag",
                comment: "Title of the alert when the store cannot be created in the store creation flow."
            )
            static let message = NSLocalizedString(
                "Let's try again in a moment. If the issue persists, please contact support.",
                comment: "Message of the alert when the store cannot be created due to the domain in the store creation flow."
            )
            static let retryAction = NSLocalizedString(
                "Retry",
                comment: "Message of the alert when the store cannot be created in the store creation flow."
            )
            static let cancelActionTitle = NSLocalizedString(
                "Cancel",
                comment: "Button title to dismiss the alert when the store cannot be created in the store creation flow."
            )
        }
    }

    enum Constants {
        static let jetpackCheckRetryInterval: TimeInterval = 10
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
