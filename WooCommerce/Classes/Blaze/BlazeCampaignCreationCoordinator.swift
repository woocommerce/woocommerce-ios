import UIKit
import Yosemite
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics

/// Blaze entry points.
enum BlazeSource {
    /// From the Blaze campaign list
    case campaignList
    /// From the Blaze intro view
    case introView
    /// From the Create campaign button on the Blaze section of the My Store screen
    case myStoreSection
    /// From the "Promote with Blaze" button on product form
    case productDetailPromoteButton
}

/// Coordinates navigation into the entry of the Blaze creation flow.
final class BlazeCampaignCreationCoordinator: Coordinator {
    enum CreateCampaignDestination: Equatable {
        case productSelector
        case campaignForm(productID: Int64) // Blaze Campaign form requires a product ID to promote.
        case noProductAvailable
    }
    private lazy var blazeNavigationController = WooNavigationController()
    private var blazeCreationEntryDestination: CreateCampaignDestination = .noProductAvailable

    /// Product ResultsController.
    /// Fetch limit is set to 2 to check if there's multiple products in the site, without having to fetch all products.
    private lazy var productResultsController: ResultsController<StorageProduct> = {
        let predicate = NSPredicate(format: "siteID == %lld AND statusKey ==[c] %@",
                                    siteID,
                                    ProductStatus.published.rawValue)
        return ResultsController<StorageProduct>(storageManager: storageManager,
                                                 matching: predicate,
                                                 fetchLimit: 2,
                                                 sortOrder: .dateDescending)
    }()

    private let siteID: Int64
    private let siteURL: String
    private let productID: Int64?
    private let source: BlazeSource
    private let shouldShowIntro: Bool
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let analytics: Analytics
    let navigationController: UINavigationController
    private let didSelectCreateCampaign: ((BlazeSource) -> Void)?
    private let onCampaignCreated: () -> Void

    private var bottomSheetPresenter: BottomSheetPresenter?
    private var addProductCoordinator: AddProductCoordinator?

    init(siteID: Int64,
         siteURL: String,
         productID: Int64? = nil,
         source: BlazeSource,
         shouldShowIntro: Bool,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         navigationController: UINavigationController,
         didSelectCreateCampaign: ((BlazeSource) -> Void)? = nil,
         analytics: Analytics = ServiceLocator.analytics,
         onCampaignCreated: @escaping () -> Void) {
        self.siteID = siteID
        self.siteURL = siteURL
        self.productID = productID
        self.source = source
        self.shouldShowIntro = shouldShowIntro
        self.stores = stores
        self.storageManager = storageManager
        self.navigationController = navigationController
        self.didSelectCreateCampaign = didSelectCreateCampaign
        self.onCampaignCreated = onCampaignCreated
        self.analytics = analytics

        configureResultsController()
    }

    func start() {
        guard shouldShowIntro else {
            startCreationFlow(from: source)
            return
        }
        presentIntroScreen { [weak self] in
            self?.analytics.track(event: .Blaze.blazeEntryPointTapped(source: .introView))
            self?.startCreationFlow(from: .introView)
        }
    }
}

private extension BlazeCampaignCreationCoordinator {
    func presentIntroScreen(onCreateCampaign: @escaping () -> Void) {
        let onDismissClosure = { [weak self] in
            guard let self else { return }
            navigationController.dismiss(animated: true)
        }
        let introController: UIViewController = BlazeCreateCampaignIntroController(onCreateCampaign: onCreateCampaign,
                                                                                   onDismiss: onDismissClosure)

        navigationController.present(introController, animated: true)
        analytics.track(event: .Blaze.blazeEntryPointDisplayed(source: .introView))
    }

    func startCreationFlow(from source: BlazeSource) {
        let navigationHandler = { [weak self] in
            guard let self else { return }
            switch blazeCreationEntryDestination {
            case .productSelector:
                navigateToBlazeProductSelector()
            case .campaignForm(let productID):
                navigateToNativeCampaignCreation(productID: productID)
            case .noProductAvailable:
                presentNoProductAlert()
            }
        }

        /// Force dismissing any presented view to avoid issue presenting the creation flow.
        if navigationController.presentedViewController != nil {
            navigationController.dismiss(animated: true, completion: navigationHandler)
        } else {
             navigationHandler()
        }
    }

    func configureResultsController() {
        productResultsController.onDidChangeContent = { [weak self] in
            self?.updateCreateCampaignDestination()
        }
        productResultsController.onDidResetContent = { [weak self] in
            self?.updateCreateCampaignDestination()
        }

        do {
            try productResultsController.performFetch()
            updateCreateCampaignDestination()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    /// Determine whether to use the existing WebView solution, or go with native Blaze campaign creation.
    func updateCreateCampaignDestination() {
        blazeCreationEntryDestination = determineDestination()
    }

    /// For native Blaze campaign creation, determine destination based existence of productID, or if not then
    /// based on number of eligible products.
    func determineDestination() -> CreateCampaignDestination {
        if let productID = productID {
            return .campaignForm(productID: productID)
        } else {
            let fetchedObjects = productResultsController.fetchedObjects
            if fetchedObjects.count > 1 {
                return .productSelector
            } else if fetchedObjects.count == 1, let firstProduct = fetchedObjects.first {
                return .campaignForm(productID: firstProduct.productID)
            }
            else {
                return .noProductAvailable
            }
        }
    }

    /// Handles navigation to the native Blaze creation
    func navigateToNativeCampaignCreation(productID: Int64) {
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: siteID,
                                                           productID: productID,
                                                           storage: storageManager,
                                                           onCompletion: { [weak self] in
            Task { @MainActor [weak self] in
                await self?.restoreBlazeOnDashboardIfNeeded()
                self?.onCampaignCreated()
                self?.dismissCampaignCreation()
            }
        })
        let controller = BlazeCampaignCreationFormHostingController(viewModel: viewModel)
        controller.hidesBottomBarWhenPushed = true

        // This function can be called from navigateToBlazeProductSelector(), in which case we need to show the
        // Campaign Creation Form from blazeNavigationController.
        // Otherwise, we show it from the current navigation controller.
        if blazeNavigationController.presentingViewController != nil {
            blazeNavigationController.show(controller, sender: self)
        } else {
            navigationController.show(controller, sender: self)
        }
    }

    /// Handles navigation to the Blaze product selector view
    func navigateToBlazeProductSelector() {
        let controller: ProductSelectorViewController = {
            let productSelectorViewModel = ProductSelectorViewModel(
                siteID: siteID,
                source: .blaze,
                onProductSelectionStateChanged: { [weak self] product, _ in
                    guard let self else { return }

                    // Navigate to Campaign Creation Form once any type of product is selected.
                    navigateToNativeCampaignCreation(productID: product.productID)
                },
                onCloseButtonTapped: { [weak self] in
                    guard let self else { return }

                    navigationController.dismiss(animated: true, completion: nil)
                }
            )
            return ProductSelectorViewController(configuration: .configurationForBlaze,
                                                 viewModel: productSelectorViewModel)
        }()

        blazeNavigationController.viewControllers = [controller]
        navigationController.present(blazeNavigationController, animated: true, completion: nil)
    }

    func presentNoProductAlert() {
        let alert = UIAlertController(title: Localization.NoProductAlert.title,
                                      message: Localization.NoProductAlert.message,
                                      preferredStyle: .alert)
        let createAction = UIAlertAction(title: Localization.NoProductAlert.createProduct, style: .default) { [weak self] _ in
            self?.startProductCreation()
        }
        let cancelAction = UIAlertAction(title: Localization.NoProductAlert.cancel, style: .cancel)
        alert.addAction(createAction)
        alert.addAction(cancelAction)
        navigationController.dismiss(animated: true) { [weak self] in
            self?.navigationController.present(alert, animated: true)
        }
    }

    func startProductCreation() {
        let coordinator = AddProductCoordinator(siteID: siteID,
                                                source: .blazeCampaignCreation,
                                                sourceView: nil,
                                                sourceNavigationController: navigationController,
                                                isFirstProduct: true)
        addProductCoordinator = coordinator
        coordinator.start()
    }
}

// MARK: - Completion handler
private extension BlazeCampaignCreationCoordinator {
    func dismissCampaignCreation() {
        // Checks if we are presenting or pushing the creation flow to dismiss accordingly.
        if blazeNavigationController.presentingViewController != nil {
            navigationController.dismiss(animated: true) { [weak self] in
                self?.showSuccessView()
            }
        } else {
            // Forces any presented controller to be dismissed and wait until completion to continue navigation.
            // Reason: presenting the bottom sheet will fail if the transition for the previous modal hasn't completed.
            navigationController.dismiss(animated: true) { [weak self] in
                guard let self else { return }
                let viewControllerStack = navigationController.viewControllers
                guard let index = viewControllerStack.lastIndex(where: { $0 is BlazeCampaignCreationFormHostingController }),
                      let originController = viewControllerStack[safe: index - 1] else {
                    return
                }
                navigationController.popToViewController(originController, animated: true)
                showSuccessView()
            }
        }
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
            sheet.detents = [.medium(), .large()]
        })
    }

    @MainActor
    func restoreBlazeOnDashboardIfNeeded() async {
        guard var cards = await loadDashboardCards(),
              let cardIndex = cards.firstIndex(where: { $0.type == .blaze && !$0.enabled }) else {
            return
        }
        cards[cardIndex] = DashboardCard(type: .blaze, availability: .show, enabled: true)
        stores.dispatch(AppSettingsAction.setDashboardCards(siteID: siteID, cards: cards))
    }

    @MainActor
    func loadDashboardCards() async -> [DashboardCard]? {
        await withCheckedContinuation { continuation in
            stores.dispatch(AppSettingsAction.loadDashboardCards(siteID: siteID, onCompletion: { cards in
                continuation.resume(returning: cards)
            }))
        }
    }
}

private extension BlazeCampaignCreationCoordinator {
    enum Localization {
        static let successTitle = NSLocalizedString(
            "blazeCampaignCreationCoordinator.successTitle",
            value: "Ready to Go!",
            comment: "Title of the celebration view when a Blaze campaign is successfully created."
        )
        static let successSubtitle = NSLocalizedString(
            "blazeCampaignCreationCoordinator.successSubtitle",
            value: "We're reviewing your campaign. It'll be live within 24 hours. Exciting times ahead for your sales!",
            comment: "Subtitle of the celebration view when a Blaze campaign is successfully created."
        )
        static let successCTA = NSLocalizedString(
            "blazeCampaignCreationCoordinator.successCTA",
            value: "Done",
            comment: "Button to dismiss the celebration view when a Blaze campaign is successfully created."
        )
        enum NoProductAlert {
            static let title = NSLocalizedString(
                "blazeCampaignCreationCoordinator.NoProductAlert.title",
                value: "No product found",
                comment: "Title of the alert when attempting to start Blaze campaign creation flow without any product in the store"
            )
            static let message = NSLocalizedString(
                "blazeCampaignCreationCoordinator.NoProductAlert.message",
                value: "You currently don’t have a product available for promotion. Would you like to create a product now?",
                comment: "Message of the alert when attempting to start Blaze campaign creation flow without any product in the store"
            )
            static let cancel = NSLocalizedString(
                "blazeCampaignCreationCoordinator.NoProductAlert.cancel",
                value: "Cancel",
                comment: "Button to dismiss the alert when attempting to start Blaze campaign creation flow without any product in the store"
            )
            static let createProduct = NSLocalizedString(
                "blazeCampaignCreationCoordinator.NoProductAlert.createProduct",
                value: "Create Product",
                comment: "Button to create a product when attempting to start Blaze campaign creation flow without any product in the store"
            )
        }
    }
}
