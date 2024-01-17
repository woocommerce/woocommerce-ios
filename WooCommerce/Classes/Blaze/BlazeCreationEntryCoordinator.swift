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
        let controller = BlazeCampaignCreationFormHostingController(
            viewModel: .init(siteID: self.siteID,
                             productID: productID,
                             onCompletion: self.onCampaignCreated
                 )
        )

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
            guard let self else { return }
            self.onCampaignCreated()
        }
        let webViewController = AuthenticatedWebViewController(viewModel: webViewModel)
        navigationController.show(webViewController, sender: self)
        didSelectCreateCampaign?(source)
    }

    /// Handles navigation to the Blaze product selector view
    func navigateToBlazeProductSelector(source: BlazeSource) {
        // View controller for product selector before going to campaign creation form.
        var productSelectorViewController: ProductSelectorViewController {
            let productSelectorViewModel = ProductSelectorViewModel(
                siteID: siteID,
                onProductSelectionStateChanged: { [weak self] product in
                    guard let self = self else { return }

                    // Navigate to Campaign Creation Form once any type of product is selected.
                    navigateToNativeCampaignCreation(source: source, productID: product.productID)
                },
                onCloseButtonTapped: { [weak self] in
                    guard let self = self else { return }

                    navigationController.dismiss(animated: true, completion: nil)
                }
            )
            return ProductSelectorViewController(configuration: ProductSelectorView.Configuration.configurationForBlaze,
                                                 source: .blaze,
                                                 viewModel: productSelectorViewModel)
        }

        blazeNavigationController.viewControllers = [productSelectorViewController]
        navigationController.present(blazeNavigationController, animated: true, completion: nil)
    }
}
