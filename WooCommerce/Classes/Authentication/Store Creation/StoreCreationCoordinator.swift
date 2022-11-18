import Combine
import UIKit
import Yosemite
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

    // MARK: - Store creation M2

    /// This property is kept as a lazy var instead of a dependency in the initializer because `InAppPurchasesForWPComPlansManager` is a @MainActor.
    /// If it's passed in the initializer, all call sites have to become @MainActor which results in too many changes.
    @MainActor
    private lazy var iapManager: InAppPurchasesForWPComPlansProtocol = {
        if featureFlagService.isFeatureFlagEnabled(.storeCreationM2WithInAppPurchasesEnabled) {
            return InAppPurchasesForWPComPlansManager(stores: stores)
        } else {
            return MockInAppPurchases()
        }
    }()

    @Published private var siteIDFromStoreCreation: Int64?
    private var jetpackSiteSubscription: AnyCancellable?

    private let stores: StoresManager
    private let analytics: Analytics
    private let source: Source
    private let storePickerViewModel: StorePickerViewModel
    private let switchStoreUseCase: SwitchStoreUseCaseProtocol
    private let featureFlagService: FeatureFlagService

    init(source: Source,
         navigationController: UINavigationController,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         iapManager: InAppPurchasesForWPComPlansProtocol? = nil) {
        self.source = source
        self.navigationController = navigationController
        // Passing the `standard` configuration to include sites without WooCommerce (`isWooCommerceActive = false`).
        self.storePickerViewModel = .init(configuration: .standard,
                                          stores: stores,
                                          storageManager: storageManager,
                                          analytics: analytics)
        self.switchStoreUseCase = SwitchStoreUseCase(stores: stores, storageManager: storageManager)
        self.stores = stores
        self.analytics = analytics
        self.featureFlagService = featureFlagService

        Task { @MainActor in
            if let iapManager {
                self.iapManager = iapManager
            }
        }
    }

    func start() {
        guard featureFlagService.isFeatureFlagEnabled(.storeCreationM2) else {
            return startStoreCreationM1()
        }
        Task { @MainActor in
            do {
                presentIAPEligibilityInProgressView()
                guard await iapManager.inAppPurchasesAreSupported() else {
                    throw PlanPurchaseError.iapNotSupported
                }
                let products = try await iapManager.fetchProducts()
                guard let product = products.first,
                      product.id == Constants.planIdentifier else {
                    throw PlanPurchaseError.noMatchingProduct
                }
                guard try await iapManager.userIsEntitledToProduct(with: product.id) == false else {
                    throw PlanPurchaseError.productNotEligible
                }
                navigationController.dismiss(animated: true) { [weak self] in
                    self?.startStoreCreationM2(planToPurchase: product)
                }
            } catch {
                navigationController.dismiss(animated: true) { [weak self] in
                    self?.startStoreCreationM1()
                }
            }
        }
    }
}

private extension StoreCreationCoordinator {
    func startStoreCreationM1() {
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

        presentStoreCreation(viewController: webNavigationController)
    }

    func startStoreCreationM2(planToPurchase: WPComPlanProduct) {
        let storeCreationNavigationController = WooNavigationController()
        storeCreationNavigationController.navigationBar.prefersLargeTitles = true

        let storeNameForm = StoreNameFormHostingController { [weak self] storeName in
            self?.showDomainSelector(from: storeCreationNavigationController,
                                     storeName: storeName,
                                     planToPurchase: planToPurchase)
        } onClose: { [weak self] in
            self?.showDiscardChangesAlert()
        }
        storeCreationNavigationController.pushViewController(storeNameForm, animated: false)

        presentStoreCreation(viewController: storeCreationNavigationController)
    }

    func presentStoreCreation(viewController: UIViewController) {
        // If the navigation controller is already presenting another view, the view needs to be dismissed before store
        // creation view can be presented.
        if navigationController.presentedViewController != nil {
            navigationController.dismiss(animated: true) { [weak self] in
                self?.navigationController.present(viewController, animated: true)
            }
        } else {
            navigationController.present(viewController, animated: true)
        }
    }

    @MainActor
    func presentIAPEligibilityInProgressView() {
        let inProgressView = InProgressViewController(viewProperties:
                .init(title: Localization.WaitingForIAPEligibility.title,
                      message: Localization.WaitingForIAPEligibility.message))
        presentStoreCreation(viewController: inProgressView)
    }
}

// MARK: - Store creation M1

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

// MARK: - Store creation M2

private extension StoreCreationCoordinator {
    func showDomainSelector(from navigationController: UINavigationController,
                            storeName: String,
                            planToPurchase: WPComPlanProduct) {
        let domainSelector = DomainSelectorHostingController(viewModel: .init(initialSearchTerm: storeName),
                                                             onDomainSelection: { [weak self] domain in
            guard let self else { return }
            await self.createStoreAndContinueToStoreSummary(from: navigationController,
                                                            name: storeName,
                                                            domain: domain,
                                                            planToPurchase: planToPurchase)
        }, onSkip: {
            // TODO-8045: skip to the next step of store creation with an auto-generated domain.
        })
        navigationController.pushViewController(domainSelector, animated: false)
    }

    @MainActor
    func createStoreAndContinueToStoreSummary(from navigationController: UINavigationController,
                                              name: String,
                                              domain: String,
                                              planToPurchase: WPComPlanProduct) async {
        let result = await createStore(name: name, domain: domain)
        switch result {
        case .success(let siteResult):
            showStoreSummary(from: navigationController, result: siteResult, planToPurchase: planToPurchase)
        case .failure(let error):
            showStoreCreationErrorAlert(from: navigationController, error: error)
        }
    }

    @MainActor
    func createStore(name: String, domain: String) async -> Result<SiteCreationResult, SiteCreationError> {
        await withCheckedContinuation { continuation in
            stores.dispatch(SiteAction.createSite(name: name, domain: domain) { result in
                continuation.resume(returning: result)
            })
        }
    }

    @MainActor
    func showStoreSummary(from navigationController: UINavigationController,
                          result: SiteCreationResult,
                          planToPurchase: WPComPlanProduct) {
        let viewModel = StoreCreationSummaryViewModel(storeName: result.name, storeSlug: result.siteSlug)
        let storeSummary = StoreCreationSummaryHostingController(viewModel: viewModel) { [weak self] in
            guard let self else { return }
            self.showWPCOMPlan(from: navigationController,
                               planToPurchase: planToPurchase,
                               siteID: result.siteID)
        }
        navigationController.pushViewController(storeSummary, animated: true)
    }

    @MainActor
    func showWPCOMPlan(from navigationController: UINavigationController,
                       planToPurchase: WPComPlanProduct,
                       siteID: Int64) {
        let storePlan = StoreCreationPlanHostingController(viewModel: .init(plan: planToPurchase)) { [weak self] in
            guard let self else { return }
            await self.purchasePlan(from: navigationController, siteID: siteID, planToPurchase: planToPurchase)
        } onClose: { [weak self] in
            guard let self else { return }
            self.showDiscardChangesAlert()
        }
        navigationController.pushViewController(storePlan, animated: true)
    }

    @MainActor
    func purchasePlan(from navigationController: UINavigationController,
                      siteID: Int64,
                      planToPurchase: WPComPlanProduct) async {
        do {
            let result = try await iapManager.purchaseProduct(with: planToPurchase.id, for: siteID)
            switch result {
            case .success:
                showInProgressViewWhileWaitingForJetpackSite(from: navigationController, siteID: siteID)
            default:
                if !featureFlagService.isFeatureFlagEnabled(.storeCreationM2WithInAppPurchasesEnabled) {
                    // Since a successful result cannot be easily mocked, any result is considered a success
                    // when using a mock for IAP.
                    showInProgressViewWhileWaitingForJetpackSite(from: navigationController, siteID: siteID)
                }
                return
            }
        } catch {
            showPlanPurchaseErrorAlert(from: navigationController, error: error)
        }
    }

    @MainActor
    func showInProgressViewWhileWaitingForJetpackSite(from navigationController: UINavigationController,
                                                      siteID: Int64) {
        waitForSiteToBecomeJetpackSite(from: navigationController, siteID: siteID)
        showInProgressView(from: navigationController, viewProperties: .init(title: Localization.WaitingForJetpackSite.title, message: ""))
    }

    @MainActor
    func showInProgressView(from navigationController: UINavigationController,
                            viewProperties: InProgressViewProperties) {
        let inProgressView = InProgressViewController(viewProperties: viewProperties)
        navigationController.isNavigationBarHidden = true
        navigationController.pushViewController(inProgressView, animated: true)
    }

    @MainActor
    func showStoreCreationErrorAlert(from navigationController: UINavigationController, error: SiteCreationError) {
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
        navigationController.present(alertController, animated: true)
    }

    @MainActor
    func waitForSiteToBecomeJetpackSite(from navigationController: UINavigationController, siteID: Int64) {
        siteIDFromStoreCreation = siteID

        jetpackSiteSubscription = $siteIDFromStoreCreation
            .compactMap { $0 }
            .removeDuplicates()
            .asyncMap { [weak self] siteID -> Site? in
                // Waits for 5 seconds before syncing sites every time.
                try await Task.sleep(nanoseconds: 5_000_000_000)
                return try await self?.syncSites(forSiteThatMatchesSiteID: siteID)
            }
            // Retries 10 times with 5 seconds pause in between to wait for the newly created site to be available as a Jetpack site
            // in the WPCOM `/me/sites` response.
            .retry(10)
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] site in
                guard let self, let site else { return }
                self.showSuccessView(from: navigationController, site: site)
            }
    }

    @MainActor
    func syncSites(forSiteThatMatchesSiteID siteID: Int64) async throws -> Site {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            storePickerViewModel.refreshSites(currentlySelectedSiteID: nil) { [weak self] in
                guard let self else {
                    return continuation.resume(throwing: StoreCreationCoordinatorError.selfDeallocated)
                }
                // The newly created site often has `isJetpackThePluginInstalled=false` initially,
                // which results in a JCP site.
                // In this case, we want to retry sites syncing.
                guard let site = self.storePickerViewModel.site(thatMatchesSiteID: siteID) else {
                    return continuation.resume(throwing: StoreCreationError.newSiteUnavailable)
                }

                // When using a mock for IAP, returns the site without waiting for the site to become a Jetpack site.
                if !self.featureFlagService.isFeatureFlagEnabled(.storeCreationM2WithInAppPurchasesEnabled) {
                    return continuation.resume(returning: site)
                }

                guard site.isJetpackConnected && site.isJetpackThePluginInstalled else {
                    return continuation.resume(throwing: StoreCreationError.newSiteIsNotJetpackSite)
                }
                continuation.resume(returning: site)
            }
        }
    }

    @MainActor
    func showPlanPurchaseErrorAlert(from navigationController: UINavigationController, error: Error) {
        let alertController = UIAlertController(title: Localization.PlanPurchaseErrorAlert.title,
                                                message: Localization.PlanPurchaseErrorAlert.defaultErrorMessage,
                                                preferredStyle: .alert)
        alertController.view.tintColor = .text
        _ = alertController.addCancelActionWithTitle(Localization.StoreCreationErrorAlert.cancelActionTitle) { _ in }
        navigationController.present(alertController, animated: true)
    }

    @MainActor
    func showSuccessView(from navigationController: UINavigationController, site: Site) {
        guard let url = URL(string: site.url) else {
            return continueWithSelectedSite(site: site)
        }
        let successView = StoreCreationSuccessHostingController(siteURL: url) { [weak self] in
            self?.continueWithSelectedSite(site: site)
        }
        navigationController.pushViewController(successView, animated: true)
    }
}

private extension StoreCreationCoordinator {
    enum StoreCreationCoordinatorError: Error {
        case selfDeallocated
    }

    enum Localization {
        enum WaitingForIAPEligibility {
            static let title = NSLocalizedString(
                "We are getting ready for your store creation",
                comment: "Title of the in-progress view when waiting for the in-app purchase status before the store creation flow."
            )
            static let message = NSLocalizedString(
                "Please remain connected.",
                comment: "Message of the in-progress view when waiting for the in-app purchase status before the store creation flow."
            )
        }

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

        enum PlanPurchaseErrorAlert {
            static let title = NSLocalizedString("Issue purchasing the plan",
                                                 comment: "Title of the alert when the WPCOM plan cannot be purchased in the store creation flow.")
            static let defaultErrorMessage = NSLocalizedString(
                "Please try again and make sure you are signed in to an App Store account eligible for purchase.",
                comment: "Message of the alert when the WPCOM plan cannot be purchased in the store creation flow."
            )
            static let cancelActionTitle = NSLocalizedString(
                "OK",
                comment: "Button title to dismiss the alert when the WPCOM plan cannot be purchased in the store creation flow."
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
        // TODO: 8108 - update the identifier to production value when it's ready
        static let planIdentifier = "debug.woocommerce.ecommerce.monthly"
    }

    /// Error scenarios when purchasing a WPCOM plan.
    enum PlanPurchaseError: Error {
        /// The user is not eligible for In-App Purchases.
        case iapNotSupported
        /// There is no matching product to purchase.
        case noMatchingProduct
        /// The user is already entitled to the product, and cannot purchase it anymore.
        case productNotEligible
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
