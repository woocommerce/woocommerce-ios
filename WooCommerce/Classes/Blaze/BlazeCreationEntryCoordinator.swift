import Experiments
import UIKit
import Yosemite
import protocol Storage.StorageManagerType

/// Coordinates navigation into the entry of the Blaze creation flow.
final class BlazeCampaignCreationCoordinator: Coordinator {
    enum CreateCampaignDestination: Equatable {
        case productSelector
        case campaignForm(productID: Int64) // Blaze Campaign form requires a product ID to promote.
        case webViewForm(productID: Int64?) // Blaze WebView form can optionally take a product ID.
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
    private let storageManager: StorageManagerType
    private let featureFlagService: FeatureFlagService
    let navigationController: UINavigationController
    private let didSelectCreateCampaign: ((BlazeSource) -> Void)?
    private let onCampaignCreated: () -> Void

    private var bottomSheetPresenter: BottomSheetPresenter?

    init(siteID: Int64,
         siteURL: String,
         productID: Int64? = nil,
         source: BlazeSource,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         navigationController: UINavigationController,
         didSelectCreateCampaign: ((BlazeSource) -> Void)? = nil,
         onCampaignCreated: @escaping () -> Void) {
        self.siteID = siteID
        self.siteURL = siteURL
        self.productID = productID
        self.source = source
        self.storageManager = storageManager
        self.featureFlagService = featureFlagService
        self.navigationController = navigationController
        self.didSelectCreateCampaign = didSelectCreateCampaign
        self.onCampaignCreated = onCampaignCreated

        configureResultsController()
    }

    private func configureResultsController() {
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

    func start() {
        switch blazeCreationEntryDestination {
        case .productSelector:
            navigateToBlazeProductSelector(source: source)
        case .campaignForm(let productID):
            navigateToNativeCampaignCreation(source: source, productID: productID)
        case .webViewForm(let productID):
            navigateToWebCampaignCreation(source: source, productID: productID)
        case .noProductAvailable:
            break // TODO 11685: add error alert.
        }
    }

    /// Determine whether to use the existing WebView solution, or go with native Blaze campaign creation.
    private func updateCreateCampaignDestination() {
        if featureFlagService.isFeatureFlagEnabled(.blazei3NativeCampaignCreation) {
            blazeCreationEntryDestination = determineDestination()
        } else {
            blazeCreationEntryDestination = .webViewForm(productID: productID)
        }
    }

    /// For native Blaze campaign creation, determine destination based existence of productID, or if not then
    /// based on number of eligible products.
    private func determineDestination() -> CreateCampaignDestination {
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
    func navigateToNativeCampaignCreation(source: BlazeSource, productID: Int64) {
        let viewModel = BlazeCampaignCreationFormViewModel(siteID: siteID,
                                                           productID: productID,
                                                           onCompletion: { [weak self] in
            self?.onCampaignCreated()
            self?.dismissCampaignCreation {
                self?.showSuccessView()
            }
        })
        let controller = BlazeCampaignCreationFormHostingController(viewModel: viewModel)

        // This function can be called from navigateToBlazeProductSelector(), in which case we need to show the
        // Campaign Creation Form from blazeNavigationController.
        // Otherwise, we show it from the current navigation controller.
        if blazeNavigationController.presentingViewController != nil {
            blazeNavigationController.show(controller, sender: self)
        } else {
            navigationController.show(controller, sender: self)
        }
    }

    /// Handles navigation to the webview Blaze creation
    func navigateToWebCampaignCreation(source: BlazeSource, productID: Int64?) {
        let webViewModel = BlazeWebViewModel(siteID: siteID,
                                             source: source,
                                             siteURL: siteURL,
                                             productID: productID) { [weak self] in
            self?.onCampaignCreated()
            self?.dismissCampaignCreation {
                self?.showSuccessView()
            }
        }
        let webViewController = AuthenticatedWebViewController(viewModel: webViewModel)
        navigationController.show(webViewController, sender: self)
        didSelectCreateCampaign?(source)
    }

    /// Handles navigation to the Blaze product selector view
    func navigateToBlazeProductSelector(source: BlazeSource) {
        let controller: ProductSelectorViewController = {
            let productSelectorViewModel = ProductSelectorViewModel(
                siteID: siteID,
                onProductSelectionStateChanged: { [weak self] product in
                    guard let self else { return }

                    // Navigate to Campaign Creation Form once any type of product is selected.
                    navigateToNativeCampaignCreation(source: source, productID: product.productID)
                },
                onCloseButtonTapped: { [weak self] in
                    guard let self else { return }

                    navigationController.dismiss(animated: true, completion: nil)
                }
            )
            return ProductSelectorViewController(configuration: .configurationForBlaze,
                                                 source: .blaze,
                                                 viewModel: productSelectorViewModel)
        }()

        blazeNavigationController.viewControllers = [controller]
        navigationController.present(blazeNavigationController, animated: true, completion: nil)
    }
}

// MARK: - Completion handler
private extension BlazeCampaignCreationCoordinator {
    func dismissCampaignCreation(completionHandler: @escaping () -> Void) {
        // For the web flow, simply pop the last view controller
        guard featureFlagService.isFeatureFlagEnabled(.blazei3NativeCampaignCreation) else {
            navigationController.popViewController(animated: true)
            completionHandler()
            return
        }

        // Checks if we are presenting or pushing the creation flow to dismiss accordingly.
        if blazeNavigationController.presentingViewController != nil {
            navigationController.dismiss(animated: true, completion: completionHandler)
        } else {
            let viewControllerStack = navigationController.viewControllers
            guard let index = viewControllerStack.lastIndex(where: { $0 is BlazeCampaignCreationFormHostingController }),
                  let originController = viewControllerStack[safe: index - 1] else {
                return
            }
            navigationController.popToViewController(originController, animated: true)
            completionHandler()
        }
    }

    func showSuccessView() {
        bottomSheetPresenter = buildBottomSheetPresenter()
        let controller = CelebrationHostingController(
            title: Localization.successTitle,
            subtitle: Localization.successSubtitle,
            closeButtonTitle: Localization.successCTA,
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
    }
}
