import UIKit
import Yosemite
import WooFoundation
import protocol Storage.StorageManagerType

/// Controls navigation for the flow to add a product given a navigation controller.
/// This class is not meant to be retained so that its life cycle is throughout the navigation. Example usage:
///
/// let coordinator = AddProductCoordinator(...)
/// coordinator.start()
///
final class AddProductCoordinator: Coordinator {
    var navigationController: UINavigationController

    private let siteID: Int64
    private let sourceBarButtonItem: UIBarButtonItem?
    private let sourceView: UIView?
    private let productImageUploader: ProductImageUploaderProtocol
    private let isProductCreationTypeEnabled: Bool
    private let storage: StorageManagerType

    /// ResultController to to track the current product count.
    ///
    private lazy var productsResultsController: ResultsController<StorageProduct> = {
        let predicate = \StorageProduct.siteID == siteID
        let controller = ResultsController<StorageProduct>(storageManager: storage, matching: predicate, sortedBy: [])
        try? controller.performFetch()
        return controller
    }()

    init(siteID: Int64,
         sourceBarButtonItem: UIBarButtonItem,
         sourceNavigationController: UINavigationController,
         isProductCreationTypeEnabled: Bool = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.productsOnboarding),
         storage: StorageManagerType = ServiceLocator.storageManager,
         productImageUploader: ProductImageUploaderProtocol = ServiceLocator.productImageUploader) {
        self.siteID = siteID
        self.sourceBarButtonItem = sourceBarButtonItem
        self.sourceView = nil
        self.navigationController = sourceNavigationController
        self.productImageUploader = productImageUploader
        self.isProductCreationTypeEnabled = isProductCreationTypeEnabled
        self.storage = storage
    }

    init(siteID: Int64,
         sourceView: UIView,
         sourceNavigationController: UINavigationController,
         isProductCreationTypeEnabled: Bool = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.productsOnboarding),
         storage: StorageManagerType = ServiceLocator.storageManager,
         productImageUploader: ProductImageUploaderProtocol = ServiceLocator.productImageUploader) {
        self.siteID = siteID
        self.sourceBarButtonItem = nil
        self.sourceView = sourceView
        self.navigationController = sourceNavigationController
        self.productImageUploader = productImageUploader
        self.isProductCreationTypeEnabled = isProductCreationTypeEnabled
        self.storage = storage
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func start() {
        if shouldPresentProductCreationBottomSheet() {
            presentProductCreationTypeBottomSheet()
        } else {
            presentProductTypeBottomSheet(creationType: .manual)
        }
    }
}

// MARK: Navigation
private extension AddProductCoordinator {

    /// Defines if the product creation bottom sheet should be presented.
    /// Currently returns `true` when the feature is enabled and the number of products is fewer than 3.
    ///
    func shouldPresentProductCreationBottomSheet() -> Bool {
        isProductCreationTypeEnabled && productsResultsController.numberOfObjects < 3
    }

    func presentProductCreationTypeBottomSheet() {
        let title = NSLocalizedString("How do you want to start?",
                                      comment: "Message title of bottom sheet for selecting a template or manual product")
        let viewProperties = BottomSheetListSelectorViewProperties(title: title)
        let command = ProductCreationTypeSelectorCommand { selectedCreationType in
            // TODO: Add analytics
            self.presentProductTypeBottomSheet(creationType: selectedCreationType)
        }
        let productTypesListPresenter = BottomSheetListSelectorPresenter(viewProperties: viewProperties, command: command)
        productTypesListPresenter.show(from: navigationController, sourceView: sourceView, sourceBarButtonItem: sourceBarButtonItem, arrowDirections: .any)
    }

    func presentProductTypeBottomSheet(creationType: ProductCreationType) {
        let title = NSLocalizedString("Select a product type",
                                      comment: "Message title of bottom sheet for selecting a product type to create a product")
        let viewProperties = BottomSheetListSelectorViewProperties(title: title)
        let command = ProductTypeBottomSheetListSelectorCommand(selected: nil) { selectedBottomSheetProductType in
            ServiceLocator.analytics.track(.addProductTypeSelected, withProperties: ["product_type": selectedBottomSheetProductType.productType.rawValue])
            self.navigationController.dismiss(animated: true) {
                self.presentProductForm(bottomSheetProductType: selectedBottomSheetProductType)
            }
        }

        switch creationType {
        case .template:
            command.data = [.simple(isVirtual: false), .simple(isVirtual: true), .variable]
        case .manual:
            command.data = [.simple(isVirtual: false), .simple(isVirtual: true), .variable, .grouped, .affiliate]
        }

        let productTypesListPresenter = BottomSheetListSelectorPresenter(viewProperties: viewProperties, command: command)

        // `topmostPresentedViewController` is used because another bottom sheet could have been presented before.
        productTypesListPresenter.show(from: navigationController.topmostPresentedViewController,
                                       sourceView: sourceView,
                                       sourceBarButtonItem: sourceBarButtonItem,
                                       arrowDirections: .any)
    }

    func presentProductForm(bottomSheetProductType: BottomSheetProductType) {
        guard let product = ProductFactory().createNewProduct(type: bottomSheetProductType.productType,
                                                              isVirtual: bottomSheetProductType.isVirtual,
                                                              siteID: siteID) else {
            assertionFailure("Unable to create product of type: \(bottomSheetProductType)")
            return
        }
        let model = EditableProductModel(product: product)

        let currencyCode = ServiceLocator.currencySettings.currencyCode
        let currency = ServiceLocator.currencySettings.symbol(from: currencyCode)
        let productImageActionHandler = productImageUploader
            .actionHandler(key: .init(siteID: product.siteID,
                                      productOrVariationID: .product(id: model.productID),
                                      isLocalID: true),
                           originalStatuses: model.imageStatuses)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .add,
                                             productImageActionHandler: productImageActionHandler)
        let viewController = ProductFormViewController(viewModel: viewModel,
                                                       eventLogger: ProductFormEventLogger(),
                                                       productImageActionHandler: productImageActionHandler,
                                                       currency: currency,
                                                       presentationStyle: .navigationStack)
        // Since the Add Product UI could hold local changes, disables the bottom bar (tab bar) to simplify app states.
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }
}
