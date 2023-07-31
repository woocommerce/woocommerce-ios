import Combine
import UIKit
import Yosemite
import enum Networking.SiteCreationFlow
import protocol Experiments.FeatureFlagService
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

    // MARK: - Store creation M1

    @Published private var possibleSiteURLsFromStoreCreation: Set<String> = []
    private var possibleSiteURLsFromStoreCreationSubscription: AnyCancellable?

    private var jetpackSiteSubscription: AnyCancellable?

    private let stores: StoresManager
    private let analytics: Analytics
    private let source: Source
    private let prefillStoreName: String?
    private let storePickerViewModel: StorePickerViewModel
    private let switchStoreUseCase: SwitchStoreUseCaseProtocol
    private let featureFlagService: FeatureFlagService
    private let localNotificationScheduler: LocalNotificationScheduler
    private var jetpackCheckRetryInterval: TimeInterval = 10

    private weak var storeCreationProgressViewModel: StoreCreationProgressViewModel?
    private var statusChecker: StoreCreationStatusChecker?

    init(source: Source,
         navigationController: UINavigationController,
         prefillStoreName: String? = nil,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         purchasesManager: InAppPurchasesForWPComPlansProtocol? = nil,
         pushNotesManager: PushNotesManager = ServiceLocator.pushNotesManager) {
        self.source = source
        self.navigationController = navigationController
        self.prefillStoreName = prefillStoreName
        // Passing the `standard` configuration to include sites without WooCommerce (`isWooCommerceActive = false`).
        self.storePickerViewModel = .init(configuration: .standard,
                                          stores: stores,
                                          storageManager: storageManager,
                                          analytics: analytics)
        self.switchStoreUseCase = SwitchStoreUseCase(stores: stores, storageManager: storageManager)
        self.stores = stores
        self.analytics = analytics
        self.featureFlagService = featureFlagService
        self.localNotificationScheduler = .init(pushNotesManager: pushNotesManager, stores: stores)
    }

    func start() {
        Task { @MainActor in
            let storeCreationNavigationController = WooNavigationController()
            startStoreCreation(from: storeCreationNavigationController)
            await presentStoreCreation(viewController: storeCreationNavigationController)
        }
    }
}

private extension StoreCreationCoordinator {

    @MainActor
    func startStoreCreation(from navigationController: UINavigationController) {
        navigationController.navigationBar.prefersLargeTitles = true
        // Disables interactive dismissal of the store creation modal.
        navigationController.isModalInPresentation = true

        let isProfilerEnabled = featureFlagService.isFeatureFlagEnabled(.storeCreationM3Profiler)
        let continueAfterEnteringStoreName = { [weak self] storeName in
            if isProfilerEnabled {
                /// `storeCreationM3Profiler` is currently disabled.
                /// Before enabling it again, make sure the onboarding questions are properly sent on the trial flow around line `343`.
                /// Ref: https://github.com/woocommerce/woocommerce-ios/issues/9326#issuecomment-1490012032
                ///
                self?.showCategoryQuestion(from: navigationController, storeName: storeName)
            } else {
                self?.showFreeTrialSummaryView(from: navigationController, storeName: storeName, profilerData: nil)
            }
        }
        let storeNameForm = StoreNameFormHostingController(prefillStoreName: prefillStoreName) { [weak self] storeName in
            self?.scheduleLocalNotificationToSubscribeFreeTrial(storeName: storeName)
            continueAfterEnteringStoreName(storeName)
        } onClose: { [weak self] in
            self?.showDiscardChangesAlert(flow: .native)
        } onSupport: { [weak self] in
            self?.showSupport(from: navigationController)
        }
        navigationController.pushViewController(storeNameForm, animated: true)
        analytics.track(event: .StoreCreation.siteCreationStep(step: .storeName))

        // Navigate to profiler question screen when store name is prefilled upon launching app from local notification
        if let prefillStoreName {
            continueAfterEnteringStoreName(prefillStoreName)
        }
    }

    @MainActor
    func presentStoreCreation(viewController: UIViewController) async {
        await withCheckedContinuation { continuation in
            // If the navigation controller is already presenting another view, the view needs to be dismissed before store
            // creation view can be presented.
            if navigationController.presentedViewController != nil {
                navigationController.dismiss(animated: true) { [weak self] in
                    guard let self else {
                        return continuation.resume()
                    }
                    self.navigationController.present(viewController, animated: true) {
                        continuation.resume()
                    }
                }
            } else {
                navigationController.present(viewController, animated: true) {
                    continuation.resume()
                }
            }
        }
    }

    /// Shows an alert with default error message
    func showStoreCreationDefaultErrorAlert(from navigationController: UINavigationController) {
        let alertController = UIAlertController(title: Localization.StoreCreationErrorAlert.title,
                                                message: Localization.StoreCreationErrorAlert.defaultErrorMessage,
                                                preferredStyle: .alert)
        alertController.view.tintColor = .text
        alertController.addCancelActionWithTitle(Localization.StoreCreationErrorAlert.cancelActionTitle) { _ in }
        navigationController.present(alertController, animated: true)
    }
}

// MARK: - Store creation M1

private extension StoreCreationCoordinator {
    func observeSiteURLsFromStoreCreation() {

        // Timestamp when we start observing times. Needed to track the store creating waiting duration.
        let waitingTimeStart = Date()

        possibleSiteURLsFromStoreCreationSubscription = $possibleSiteURLsFromStoreCreation
            .filter { $0.isEmpty == false }
            .removeDuplicates()
            // There are usually three URLs in the webview that return a site URL - two with `*.wordpress.com` and the other the final URL.
            .debounce(for: .seconds(5), scheduler: DispatchQueue.main)
            .tryAsyncMap { [weak self] possibleSiteURLs -> Site? in
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
                self.trackSiteCreatedEvent(site: site, flow: .web, timeAtStart: waitingTimeStart)
                self.continueWithSelectedSite(site: site)
            }
    }

    @objc func handleStoreCreationCloseAction() {
        showDiscardChangesAlert(flow: .web)
    }

    func handleStoreCreationResult(_ result: Result<String, Error>) {
        switch result {
        case .success(let siteURL):
            // There could be multiple site URLs from the completion URL in the webview, and only one
            // of them matches the final site URL from WPCOM `/me/sites` endpoint.
            possibleSiteURLsFromStoreCreation.insert(siteURL)
        case .failure(let error):
            analytics.track(event: .StoreCreation.siteCreationFailed(source: source.analyticsValue, error: error, flow: .web, isFreeTrial: false))
            DDLogError("Store creation error: \(error)")

            // Dismiss store creation webview before showing error alert
            navigationController.dismiss(animated: true) { [weak self] in
                guard let self else { return }

                // Show error alert
                self.showStoreCreationDefaultErrorAlert(from: self.navigationController)
            }
        }
    }

    @MainActor
    func syncSites(forSiteThatMatchesPossibleURLs possibleURLs: Set<String>) async throws -> Site {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.storePickerViewModel.refreshSites(currentlySelectedSiteID: nil) { [weak self] in
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
        switchStoreUseCase.switchStore(with: site.siteID) { [weak self] siteChanged in
            guard let self else { return }

            // Shows `My store` tab by default.
            MainTabBarController.switchToMyStoreTab(animated: true)

            self.navigationController.dismiss(animated: true)
        }
    }

    func showDiscardChangesAlert(flow: WooAnalyticsEvent.StoreCreation.Flow) {
        let alert = UIAlertController(title: Localization.DiscardChangesAlert.title,
                                      message: Localization.DiscardChangesAlert.message,
                                      preferredStyle: .alert)
        alert.view.tintColor = .text

        alert.addDestructiveActionWithTitle(Localization.DiscardChangesAlert.confirmActionTitle) { [weak self] _ in
            guard let self else { return }
            self.analytics.track(event: .StoreCreation.siteCreationDismissed(source: self.source.analyticsValue, flow: flow, isFreeTrial: true))
            self.navigationController.dismiss(animated: true)
        }

        alert.addCancelActionWithTitle(Localization.DiscardChangesAlert.cancelActionTitle) { _ in }

        // Presents the alert with the presented webview.
        navigationController.topmostPresentedViewController.present(alert, animated: true)
    }

    func showSupport(from navigationController: UINavigationController) {
        let sourceTag = "origin:store-creation"
        let supportForm = SupportFormHostingController(viewModel: .init(sourceTag: sourceTag))
        supportForm.show(from: navigationController)
    }
}

// MARK: - Store creation M2

private extension StoreCreationCoordinator {
    @MainActor
    func showCategoryQuestion(from navigationController: UINavigationController,
                              storeName: String) {
        let questionController = StoreCreationCategoryQuestionHostingController(viewModel:
                .init(storeName: storeName) { [weak self] category in
                    guard let self else { return }
                    self.showSellingStatusQuestion(from: navigationController, storeName: storeName, category: category)
                } onSkip: { [weak self] in
                    guard let self else { return }
                    self.analytics.track(event: .StoreCreation.siteCreationProfilerQuestionSkipped(step: .profilerCategoryQuestion))
                    self.showSellingStatusQuestion(from: navigationController, storeName: storeName, category: nil)
                })
        navigationController.pushViewController(questionController, animated: true)
        analytics.track(event: .StoreCreation.siteCreationStep(step: .profilerCategoryQuestion))
    }

    @MainActor
    func showSellingStatusQuestion(from navigationController: UINavigationController,
                                   storeName: String,
                                   category: StoreCreationCategoryAnswer?) {
        let questionController = StoreCreationSellingStatusQuestionHostingController(storeName: storeName) { [weak self] sellingStatus in
            guard let self else { return }
            if sellingStatus?.sellingStatus == .alreadySellingOnline && sellingStatus?.sellingPlatforms?.isEmpty == true {
                self.analytics.track(event: .StoreCreation.siteCreationProfilerQuestionSkipped(step: .profilerSellingPlatformsQuestion))
            }
            self.showStoreCountryQuestion(from: navigationController,
                                          storeName: storeName,
                                          category: category,
                                          sellingStatus: sellingStatus)
        } onSkip: { [weak self] in
            guard let self else { return }
            self.analytics.track(event: .StoreCreation.siteCreationProfilerQuestionSkipped(step: .profilerSellingStatusQuestion))
            self.showStoreCountryQuestion(from: navigationController,
                                          storeName: storeName,
                                          category: category,
                                          sellingStatus: nil)
        }
        navigationController.pushViewController(questionController, animated: true)
        analytics.track(event: .StoreCreation.siteCreationStep(step: .profilerSellingStatusQuestion))
    }

    @MainActor
    func showStoreCountryQuestion(from navigationController: UINavigationController,
                                  storeName: String,
                                  category: StoreCreationCategoryAnswer?,
                                  sellingStatus: StoreCreationSellingStatusAnswer?) {
        let questionController = StoreCreationCountryQuestionHostingController(viewModel:
                .init(storeName: storeName) { [weak self] countryCode in
                    guard let self else { return }

                    let profilerData: SiteProfilerData = {
                        let sellingPlatforms = sellingStatus?.sellingPlatforms?.map { $0.rawValue }.sorted().joined(separator: ",")
                        return .init(name: storeName,
                                     category: category?.value,
                                     sellingStatus: sellingStatus?.sellingStatus,
                                     sellingPlatforms: sellingPlatforms,
                                     countryCode: countryCode.rawValue)
                    }()

                    self.showFreeTrialSummaryView(from: navigationController, storeName: storeName, profilerData: profilerData)
                } onSupport: { [weak self] in
                    self?.showSupport(from: navigationController)
                })
        navigationController.pushViewController(questionController, animated: true)
        analytics.track(event: .StoreCreation.siteCreationStep(step: .profilerCountryQuestion))
    }

    @MainActor
    /// Presents the free trial summary view.
    /// After user confirmation proceeds to create a store with a free trial plan.
    ///
    func showFreeTrialSummaryView(from navigationController: UINavigationController,
                                  storeName: String,
                                  profilerData: SiteProfilerData?) {
        let summaryViewController = FreeTrialSummaryHostingController(onClose: { [weak self] in
            self?.showDiscardChangesAlert(flow: .native)
        }, onContinue: { [weak self] in
            guard let self else { return }
            self.analytics.track(event: .StoreCreation.siteCreationTryForFreeTapped())
            let result = await self.createFreeTrialStore(storeName: storeName,
                                                         profilerData: profilerData)
            self.handleFreeTrialStoreCreation(from: navigationController, result: result)
        })
        navigationController.present(summaryViewController, animated: true)
    }

    /// This method creates a free trial store async:
    /// - Create a simple site
    /// - Enable Free Trial on the site
    /// - Schedule a local notification to notify the user when the site is ready
    ///
    @MainActor
    func createFreeTrialStore(storeName: String, profilerData: SiteProfilerData?) async -> Result<SiteCreationResult, SiteCreationError> {
        // Create store site
        let createStoreResult = await createStore(name: storeName, flow: .wooexpress)
        if let profilerData {
            analytics.track(event: .StoreCreation.siteCreationProfilerData(profilerData))
        }

        switch createStoreResult {
        case .success(let siteResult):

            // Enable Free trial on site
            let freeTrialResult = await enableFreeTrial(siteID: siteResult.siteID, profilerData: profilerData)
            switch freeTrialResult {
            case .success:
                cancelLocalNotificationToSubscribeFreeTrial(storeName: storeName)
                scheduleLocalNotificationWhenStoreIsReady()
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
    @MainActor
    func handleFreeTrialStoreCreation(from navigationController: UINavigationController, result: Result<SiteCreationResult, SiteCreationError>) {
        switch result {
        case .success(let siteResult):
            // Make sure that nothing is presented on the view controller before showing the loading screen
            navigationController.presentedViewController?.dismiss(animated: true)
            // Show a progress view while the free trial store is created.
            showInProgressView(from: navigationController, viewProperties: .init(title: Localization.WaitingForJetpackSite.title, message: ""))
            // Wait for jetpack to be installed
            DDLogInfo("🟢 Free trial enabled on site. Waiting for jetpack to be installed...")
            Task { @MainActor in
                await waitForSiteToBecomeJetpackSite(from: navigationController, siteID: siteResult.siteID, expectedStoreName: siteResult.name)
                analytics.track(event: .StoreCreation.siteCreationRequestSuccess(
                    siteID: siteResult.siteID,
                    domainName: siteResult.siteSlug
                ))
                analytics.track(event: .StoreCreation.siteCreationStep(step: .storeInstallation))
            }

        case .failure(let error):
            showStoreCreationErrorAlert(from: navigationController.topmostPresentedViewController, error: error)
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
    func enableFreeTrial(siteID: Int64, profilerData: SiteProfilerData?) async -> Result<Void, Error> {
        await withCheckedContinuation { continuation in
            stores.dispatch(SiteAction.enableFreeTrial(siteID: siteID, profilerData: profilerData) { result in
                continuation.resume(returning: result)
            })
        }
    }

    @MainActor
    func showInProgressView(from navigationController: UINavigationController,
                            viewProperties: InProgressViewProperties) {
        let approxSecondsToWaitForNetworkRequest = 10.0
        let viewModel = StoreCreationProgressViewModel(estimatedTimePerProgress: jetpackCheckRetryInterval + approxSecondsToWaitForNetworkRequest)
        let storeCreationProgressView = StoreCreationProgressHostingViewController(viewModel: viewModel)
        navigationController.isNavigationBarHidden = true
        self.storeCreationProgressViewModel = viewModel
        navigationController.pushViewController(storeCreationProgressView, animated: true)
    }

    @MainActor
    func showStoreCreationErrorAlert(from viewController: UIViewController, error: SiteCreationError) {
        let message: String = {
            switch error {
            case .invalidDomain, .domainExists:
                return Localization.StoreCreationErrorAlert.domainErrorMessage
            default:
                return Localization.StoreCreationErrorAlert.defaultErrorMessage
            }
        }()
        let alertController = UIAlertController(title: Localization.StoreCreationErrorAlert.title,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.view.tintColor = .text
        _ = alertController.addCancelActionWithTitle(Localization.StoreCreationErrorAlert.cancelActionTitle) { _ in }
        viewController.present(alertController, animated: true)
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

    @MainActor
    func handleCompletionStatus(siteID: Int64, site: Site?, waitingTimeStart: Date, expectedStoreName: String) {
        cancelLocalNotificationWhenStoreIsReady()
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

        storeCreationProgressViewModel?.markAsComplete()
        trackSiteCreatedEvent(site: site, flow: .native, timeAtStart: waitingTimeStart)

        /// Free trial stores should land directly on the dashboard and not show any success view.
        ///
        continueWithSelectedSite(site: site)
    }

    @MainActor
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

    @MainActor
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
    func scheduleLocalNotificationWhenStoreIsReady() {
        let notification = LocalNotification(scenario: Constants.LocalNotificationScenario.storeCreationComplete,
                                             stores: stores)
        cancelLocalNotificationWhenStoreIsReady()
        Task {
            await localNotificationScheduler.schedule(notification: notification,
                                                      // 5 minutes from now when the site is most likely ready.
                                                      trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5 * 60, repeats: false),
                                                      remoteFeatureFlag: .storeCreationCompleteNotification)
        }
    }

    func cancelLocalNotificationWhenStoreIsReady() {
        Task {
            await localNotificationScheduler.cancel(scenario: Constants.LocalNotificationScenario.storeCreationComplete)
        }
    }

    func scheduleLocalNotificationToSubscribeFreeTrial(storeName: String) {
        let notification = LocalNotification(scenario: LocalNotification.Scenario.oneDayAfterStoreCreationNameWithoutFreeTrial(storeName: storeName),
                                                   stores: stores,
                                                   userInfo: [LocalNotification.UserInfoKey.storeName: storeName])

        cancelLocalNotificationToSubscribeFreeTrial(storeName: storeName)
        Task {
            await localNotificationScheduler.schedule(notification: notification,
                                                      // Notify after 24 hours
                                                      trigger: UNTimeIntervalNotificationTrigger(timeInterval: 24 * 60 * 60,
                                                                                                 repeats: false),
                                                      remoteFeatureFlag: .oneDayAfterStoreCreationNameWithoutFreeTrial)
        }
    }

    func cancelLocalNotificationToSubscribeFreeTrial(storeName: String) {
        Task {
            await localNotificationScheduler.cancel(scenario: LocalNotification.Scenario.oneDayAfterStoreCreationNameWithoutFreeTrial(storeName: storeName))
        }
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

        enum StoreCreationErrorAlert {
            static let title = NSLocalizedString("Cannot create store",
                                                 comment: "Title of the alert when the store cannot be created in the store creation flow.")
            static let domainErrorMessage = NSLocalizedString("Please try a different domain.",
                                                 comment: "Message of the alert when the store cannot be created due to the domain in the store creation flow.")
            static let defaultErrorMessage = NSLocalizedString("Please try again.",
                                                              comment: "Message of the alert when the store cannot be created in the store creation flow.")
            static let cancelActionTitle = NSLocalizedString(
                "OK",
                comment: "Button title to dismiss the alert when the store cannot be created in the store creation flow."
            )
        }

        enum WaitingForJetpackSite {
            static let title = NSLocalizedString(
                "Creating your store",
                comment: "Title of the in-progress view when waiting for the site to become a Jetpack site " +
                "after WPCOM plan purchase in the store creation flow."
            )
        }
    }

    enum Constants {
        /// Local notification scenarios during store creation.
        enum LocalNotificationScenario {
            static let storeCreationComplete: LocalNotification.Scenario = .storeCreationComplete
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
