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
    private lazy var purchasesManager: InAppPurchasesForWPComPlansProtocol = {
        if featureFlagService.isFeatureFlagEnabled(.storeCreationM2WithInAppPurchasesEnabled) {
            return InAppPurchasesForWPComPlansManager(stores: stores)
        } else {
            return WebPurchasesForWPComPlans(stores: stores)
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
         purchasesManager: InAppPurchasesForWPComPlansProtocol? = nil) {
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
            if let purchasesManager {
                self.purchasesManager = purchasesManager
            }
        }
    }

    func start() {
        guard featureFlagService.isFeatureFlagEnabled(.storeCreationM2) else {
            return startStoreCreationM1()
        }
        Task { @MainActor in
            do {
                let inProgressView = createIAPEligibilityInProgressView()
                let storeCreationNavigationController = WooNavigationController(rootViewController: inProgressView)
                await presentStoreCreation(viewController: storeCreationNavigationController)

                guard await purchasesManager.inAppPurchasesAreSupported() else {
                    throw PlanPurchaseError.iapNotSupported
                }
                let products = try await purchasesManager.fetchProducts()
                let expectedPlanIdentifier = featureFlagService.isFeatureFlagEnabled(.storeCreationM2WithInAppPurchasesEnabled) ?
                Constants.iapPlanIdentifier: Constants.webPlanIdentifier
                guard let product = products.first,
                      product.id == expectedPlanIdentifier else {
                    throw PlanPurchaseError.noMatchingProduct
                }
                guard try await purchasesManager.userIsEntitledToProduct(with: product.id) == false else {
                    throw PlanPurchaseError.productNotEligible
                }

                startStoreCreationM2(from: storeCreationNavigationController, planToPurchase: product)
            } catch {
                let isWebviewFallbackAllowed = featureFlagService.isFeatureFlagEnabled(.storeCreationM2WithInAppPurchasesEnabled) == false
                navigationController.dismiss(animated: true) { [weak self] in
                    guard let self else { return }
                    if isWebviewFallbackAllowed {
                        self.startStoreCreationM1()
                    } else {
                        self.showIneligibleUI(from: self.navigationController, error: error)
                    }
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

        Task { @MainActor in
            await presentStoreCreation(viewController: webNavigationController)
        }
    }

    @MainActor
    func startStoreCreationM2(from navigationController: UINavigationController, planToPurchase: WPComPlanProduct) {
        navigationController.navigationBar.prefersLargeTitles = true
        // Disables interactive dismissal of the store creation modal.
        navigationController.isModalInPresentation = true

        let isProfilerEnabled = featureFlagService.isFeatureFlagEnabled(.storeCreationM3Profiler)
        let storeNameForm = StoreNameFormHostingController { [weak self] storeName in
            if isProfilerEnabled {
                self?.showCategoryQuestion(from: navigationController, storeName: storeName, planToPurchase: planToPurchase)
            } else {
                self?.showDomainSelector(from: navigationController,
                                         storeName: storeName,
                                         category: nil,
                                         sellingStatus: nil,
                                         countryCode: nil,
                                         planToPurchase: planToPurchase)
            }
        } onClose: { [weak self] in
            self?.showDiscardChangesAlert(flow: .native)
        } onSupport: { [weak self] in
            self?.showSupport(from: navigationController)
        }
        navigationController.pushViewController(storeNameForm, animated: true)
        analytics.track(event: .StoreCreation.siteCreationStep(step: .storeName))
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

    @MainActor
    func createIAPEligibilityInProgressView() -> UIViewController {
        InProgressViewController(viewProperties:
                .init(title: Localization.WaitingForIAPEligibility.title,
                      message: Localization.WaitingForIAPEligibility.message),
                                 hidesNavigationBar: true)
    }

    /// Shows UI when the user is not eligible for store creation.
    func showIneligibleUI(from navigationController: UINavigationController, error: Error) {
        let message: String
        switch error {
        case PlanPurchaseError.iapNotSupported:
            message = Localization.IAPIneligibleAlert.notSupportedMessage
        case PlanPurchaseError.productNotEligible:
            message = Localization.IAPIneligibleAlert.productNotEligibleMessage
        default:
            message = Localization.IAPIneligibleAlert.defaultMessage
        }

        let alert = UIAlertController(title: nil,
                                      message: message,
                                      preferredStyle: .alert)
        alert.view.tintColor = .text

        alert.addCancelActionWithTitle(Localization.IAPIneligibleAlert.dismissActionTitle) { _ in }

        navigationController.present(alert, animated: true)
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
                self.analytics.track(event: .StoreCreation.siteCreated(source: self.source.analyticsValue, siteURL: site.url, flow: .web))
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
            analytics.track(event: .StoreCreation.siteCreationFailed(source: source.analyticsValue, error: error, flow: .web))
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
            self.analytics.track(event: .StoreCreation.siteCreationDismissed(source: self.source.analyticsValue, flow: flow))
            self.navigationController.dismiss(animated: true)
        }

        alert.addCancelActionWithTitle(Localization.DiscardChangesAlert.cancelActionTitle) { _ in }

        // Presents the alert with the presented webview.
        navigationController.presentedViewController?.present(alert, animated: true)
    }

    func showSupport(from navigationController: UINavigationController) {
        ZendeskProvider.shared.showNewRequestIfPossible(from: navigationController, with: "origin:store-creation")
    }
}

// MARK: - Store creation M2

private extension StoreCreationCoordinator {
    @MainActor
    func showCategoryQuestion(from navigationController: UINavigationController,
                              storeName: String,
                              planToPurchase: WPComPlanProduct) {
        let questionController = StoreCreationCategoryQuestionHostingController(viewModel:
                .init(storeName: storeName) { [weak self] category in
                    guard let self else { return }
                    self.showSellingStatusQuestion(from: navigationController, storeName: storeName, category: category, planToPurchase: planToPurchase)
                } onSkip: { [weak self] in
                    // TODO: analytics
                    guard let self else { return }
                    self.showSellingStatusQuestion(from: navigationController, storeName: storeName, category: nil, planToPurchase: planToPurchase)
                })
        navigationController.pushViewController(questionController, animated: true)
        analytics.track(event: .StoreCreation.siteCreationStep(step: .profilerCategoryQuestion))
    }

    @MainActor
    func showSellingStatusQuestion(from navigationController: UINavigationController,
                                   storeName: String,
                                   category: StoreCreationCategoryAnswer?,
                                   planToPurchase: WPComPlanProduct) {
        let questionController = StoreCreationSellingStatusQuestionHostingController(storeName: storeName) { [weak self] sellingStatus in
            guard let self else { return }
            self.showStoreCountryQuestion(from: navigationController,
                                          storeName: storeName,
                                          category: category,
                                          sellingStatus: sellingStatus,
                                          planToPurchase: planToPurchase)
        } onSkip: { [weak self] in
            // TODO: analytics
            guard let self else { return }
            self.showStoreCountryQuestion(from: navigationController,
                                          storeName: storeName,
                                          category: category,
                                          sellingStatus: nil,
                                          planToPurchase: planToPurchase)
        }
        navigationController.pushViewController(questionController, animated: true)
        analytics.track(event: .StoreCreation.siteCreationStep(step: .profilerSellingStatusQuestion))
    }

    @MainActor
    func showStoreCountryQuestion(from navigationController: UINavigationController,
                                  storeName: String,
                                  category: StoreCreationCategoryAnswer?,
                                  sellingStatus: StoreCreationSellingStatusAnswer?,
                                  planToPurchase: WPComPlanProduct) {
        let questionController = StoreCreationCountryQuestionHostingController(viewModel:
                .init(storeName: storeName) { [weak self] countryCode in
                    guard let self else { return }
                    self.showDomainSelector(from: navigationController,
                                            storeName: storeName,
                                            category: category,
                                            sellingStatus: sellingStatus,
                                            countryCode: countryCode,
                                            planToPurchase: planToPurchase)
                } onSupport: { [weak self] in
                    self?.showSupport(from: navigationController)
                })
        navigationController.pushViewController(questionController, animated: true)
        analytics.track(event: .StoreCreation.siteCreationStep(step: .profilerCountryQuestion))
    }

    @MainActor
    func showDomainSelector(from navigationController: UINavigationController,
                            storeName: String,
                            category: StoreCreationCategoryAnswer?,
                            sellingStatus: StoreCreationSellingStatusAnswer?,
                            countryCode: SiteAddress.CountryCode?,
                            planToPurchase: WPComPlanProduct) {
        let domainSelector = DomainSelectorHostingController(viewModel: .init(initialSearchTerm: storeName),
                                                             onDomainSelection: { [weak self] domain in
            guard let self else { return }
            await self.createStoreAndContinueToStoreSummary(from: navigationController,
                                                            name: storeName,
                                                            category: category,
                                                            sellingStatus: sellingStatus,
                                                            countryCode: countryCode,
                                                            domain: domain,
                                                            planToPurchase: planToPurchase)
        }, onSupport: { [weak self] in
            self?.showSupport(from: navigationController)
        })
        navigationController.pushViewController(domainSelector, animated: true)
        analytics.track(event: .StoreCreation.siteCreationStep(step: .domainPicker))
    }

    @MainActor
    func createStoreAndContinueToStoreSummary(from navigationController: UINavigationController,
                                              name: String,
                                              category: StoreCreationCategoryAnswer?,
                                              sellingStatus: StoreCreationSellingStatusAnswer?,
                                              countryCode: SiteAddress.CountryCode?,
                                              domain: String,
                                              planToPurchase: WPComPlanProduct) async {
        let result = await createStore(name: name, domain: domain)
        analytics.track(event: .StoreCreation.siteCreationProfilerData(category: category,
                                                                       sellingStatus: sellingStatus,
                                                                       countryCode: countryCode))
        switch result {
        case .success(let siteResult):
            showStoreSummary(from: navigationController,
                             result: siteResult,
                             category: category,
                             countryCode: countryCode,
                             planToPurchase: planToPurchase)
        case .failure(let error):
            analytics.track(event: .StoreCreation.siteCreationFailed(source: source.analyticsValue, error: error, flow: .native))
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
                          category: StoreCreationCategoryAnswer?,
                          countryCode: SiteAddress.CountryCode?,
                          planToPurchase: WPComPlanProduct) {
        let viewModel = StoreCreationSummaryViewModel(storeName: result.name,
                                                      storeSlug: result.siteSlug,
                                                      categoryName: category?.name,
                                                      countryCode: countryCode)
        let storeSummary = StoreCreationSummaryHostingController(viewModel: viewModel) { [weak self] in
            guard let self else { return }
            self.showWPCOMPlan(from: navigationController,
                               planToPurchase: planToPurchase,
                               siteID: result.siteID,
                               siteSlug: result.siteSlug)
        } onSupport: { [weak self] in
            self?.showSupport(from: navigationController)
        }
        navigationController.pushViewController(storeSummary, animated: true)
        analytics.track(event: .StoreCreation.siteCreationStep(step: .storeSummary))
    }

    @MainActor
    func showWPCOMPlan(from navigationController: UINavigationController,
                       planToPurchase: WPComPlanProduct,
                       siteID: Int64,
                       siteSlug: String) {
        let storePlan = StoreCreationPlanHostingController(viewModel: .init(plan: planToPurchase)) { [weak self] in
            guard let self else { return }
            await self.purchasePlan(from: navigationController, siteID: siteID, siteSlug: siteSlug, planToPurchase: planToPurchase)
        } onClose: { [weak self] in
            guard let self else { return }
            self.showDiscardChangesAlert(flow: .native)
        }
        navigationController.pushViewController(storePlan, animated: true)
        analytics.track(event: .StoreCreation.siteCreationStep(step: .planPurchase))
    }

    @MainActor
    func purchasePlan(from navigationController: UINavigationController,
                      siteID: Int64,
                      siteSlug: String,
                      planToPurchase: WPComPlanProduct) async {
        do {
            let result = try await purchasesManager.purchaseProduct(with: planToPurchase.id, for: siteID)

            if featureFlagService.isFeatureFlagEnabled(.storeCreationM2WithInAppPurchasesEnabled) {
                switch result {
                case .success:
                    showInProgressViewWhileWaitingForJetpackSite(from: navigationController, siteID: siteID)
                default:
                    return
                }
            } else {
                switch result {
                case .pending:
                    showWebCheckout(from: navigationController, siteID: siteID, siteSlug: siteSlug)
                default:
                    return
                }
            }
        } catch {
            showPlanPurchaseErrorAlert(from: navigationController, error: error)
        }
    }

    @MainActor
    func showWebCheckout(from navigationController: UINavigationController, siteID: Int64, siteSlug: String) {
        let checkoutViewModel = WebCheckoutViewModel(siteSlug: siteSlug) { [weak self] in
            self?.showInProgressViewWhileWaitingForJetpackSite(from: navigationController, siteID: siteID)
        }
        let checkoutController = AuthenticatedWebViewController(viewModel: checkoutViewModel)
        navigationController.pushViewController(checkoutController, animated: true)
        analytics.track(event: .StoreCreation.siteCreationStep(step: .webCheckout))
    }

    @MainActor
    func showInProgressViewWhileWaitingForJetpackSite(from navigationController: UINavigationController,
                                                      siteID: Int64) {
        waitForSiteToBecomeJetpackSite(from: navigationController, siteID: siteID)
        showInProgressView(from: navigationController, viewProperties: .init(title: Localization.WaitingForJetpackSite.title, message: ""))
        analytics.track(event: .StoreCreation.siteCreationStep(step: .storeInstallation))
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
                guard let self else { return }
                guard let site else {
                    navigationController.dismiss(animated: true) { [weak self] in
                        guard let self else { return }
                        self.showJetpackSiteTimeoutAlert(from: self.navigationController)
                    }
                    return
                }
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

                guard site.isJetpackConnected && site.isJetpackThePluginInstalled else {
                    return continuation.resume(throwing: StoreCreationError.newSiteIsNotJetpackSite)
                }
                continuation.resume(returning: site)
            }
        }
    }

    @MainActor
    func showPlanPurchaseErrorAlert(from navigationController: UINavigationController, error: Error) {
        let errorMessage = featureFlagService.isFeatureFlagEnabled(.storeCreationM2WithInAppPurchasesEnabled) ?
        Localization.PlanPurchaseErrorAlert.defaultErrorMessage: Localization.PlanPurchaseErrorAlert.webPurchaseErrorMessage
        let alertController = UIAlertController(title: Localization.PlanPurchaseErrorAlert.title,
                                                message: errorMessage,
                                                preferredStyle: .alert)
        alertController.view.tintColor = .text
        _ = alertController.addCancelActionWithTitle(Localization.StoreCreationErrorAlert.cancelActionTitle) { _ in }
        navigationController.present(alertController, animated: true)
    }

    @MainActor
    func showSuccessView(from navigationController: UINavigationController, site: Site) {
        analytics.track(event: .StoreCreation.siteCreated(source: source.analyticsValue, siteURL: site.url, flow: .native))
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
    func showJetpackSiteTimeoutAlert(from navigationController: UINavigationController) {
        let alertController = UIAlertController(title: Localization.WaitingForJetpackSite.TimeoutAlert.title,
                                                message: Localization.WaitingForJetpackSite.TimeoutAlert.message,
                                                preferredStyle: .alert)
        alertController.view.tintColor = .text
        _ = alertController.addCancelActionWithTitle(Localization.WaitingForJetpackSite.TimeoutAlert.cancelActionTitle) { _ in }
        navigationController.present(alertController, animated: true)
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

        enum IAPIneligibleAlert {
            static let notSupportedMessage = NSLocalizedString(
                "We're sorry, but store creation is not currently available in your country in the app.",
                comment: "Message of the alert when the user cannot create a store because their App Store country is not supported."
            )
            static let productNotEligibleMessage = NSLocalizedString(
                "Sorry, but you can only create one store. Your account is already associated with an active store.",
                comment: "Message of the alert when the user cannot create a store because they already created one before."
            )
            static let defaultMessage = NSLocalizedString(
                "We're sorry, but store creation is not currently available in the app.",
                comment: "Message of the alert when the user cannot create a store for some reason."
            )
            static let dismissActionTitle = NSLocalizedString("OK",
                                                             comment: "Button title to cancel the alert when the user cannot create a store.")
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
            static let webPurchaseErrorMessage = NSLocalizedString(
                "Please try again, or exit the screen and check back on your store if you previously left the checkout screen while payment is in progress.",
                comment: "Message of the alert when the WPCOM plan cannot be purchased in a webview in the store creation flow."
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

            enum TimeoutAlert {
                static let title = NSLocalizedString(
                    "Store creation still in progress",
                    comment: "Title of the alert when the created store never becomes a Jetpack site in the store creation flow."
                )
                static let message = NSLocalizedString(
                    "The new store will be available soon in the store picker. If you have any issues, please contact support.",
                    comment: "Message of the alert when the created store never becomes a Jetpack site in the store creation flow."
                )
                static let cancelActionTitle = NSLocalizedString(
                    "OK",
                    comment: "Button title to dismiss the alert when the created store never becomes a Jetpack site in the store creation flow."
                )
            }
        }
    }

    enum Constants {
        // TODO: 8108 - update the identifier to production value when it's ready
        static let iapPlanIdentifier = "debug.woocommerce.ecommerce.monthly"
        static let webPlanIdentifier = "1021"
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
