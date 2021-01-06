import UIKit
import Yosemite

/// Controls navigation for the flow to add a product given a navigation controller.
/// This class is not meant to be retained so that its life cycle is throughout the navigation. Example usage:
///
/// let coordinator = AddProductCoordinator(...)
/// coordinator.start()
///
final class AddProductCoordinator: Coordinator {
    var navigationController: UINavigationController

    private let siteID: Int64
    private let sourceView: UIBarButtonItem

    init(siteID: Int64, sourceView: UIBarButtonItem, sourceNavigationController: UINavigationController) {
        self.siteID = siteID
        self.sourceView = sourceView
        self.navigationController = sourceNavigationController
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func start() {
        presentProductTypeBottomSheet()
    }
}

// MARK: Navigation
private extension AddProductCoordinator {
    func presentProductTypeBottomSheet() {
        let title = NSLocalizedString("Select a product type",
                                      comment: "Message title of bottom sheet for selecting a product type to create a product")
        let viewProperties = BottomSheetListSelectorViewProperties(title: title)
        let command = ProductTypeBottomSheetListSelectorCommand(selected: nil) { selectedProductType in
            ServiceLocator.analytics.track(.addProductTypeSelected, withProperties: ["product_type": selectedProductType.rawValue])
            self.navigationController.dismiss(animated: true)
            self.presentProductForm(productType: selectedProductType)
        }
        // Until we support adding a variation, adding a variable product is disabled.
        command.data = [.simple, .grouped, .affiliate]
        let productTypesListPresenter = BottomSheetListSelectorPresenter(viewProperties: viewProperties, command: command)
        productTypesListPresenter.show(from: navigationController, sourceBarButtonItem: sourceView, arrowDirections: .up)
    }

    func presentProductForm(productType: ProductType) {
        guard let product = ProductFactory().createNewProduct(type: productType, siteID: siteID) else {
            assertionFailure("Unable to create product of type: \(productType)")
            return
        }
        let model = EditableProductModel(product: product)

        let currencyCode = ServiceLocator.currencySettings.currencyCode
        let currency = ServiceLocator.currencySettings.symbol(from: currencyCode)
        let productImageActionHandler = ProductImageActionHandler(siteID: product.siteID,
                                                                  product: model)
        let isAddProductVariationsEnabled = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.addProductVariations)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .add,
                                             productImageActionHandler: productImageActionHandler)
        let viewController = ProductFormViewController(viewModel: viewModel,
                                                       eventLogger: ProductFormEventLogger(),
                                                       productImageActionHandler: productImageActionHandler,
                                                       currency: currency,
                                                       presentationStyle: .navigationStack,
                                                       isAddProductVariationsEnabled: isAddProductVariationsEnabled)
        // Since the Add Product UI could hold local changes, disables the bottom bar (tab bar) to simplify app states.
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }
}
