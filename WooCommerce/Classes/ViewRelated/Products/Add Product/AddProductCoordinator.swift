import UIKit
import Yosemite

/// Controls navigation for the in-app feedback flow. Meant to be presented modally
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
            self.navigationController.dismiss(animated: true) {
                self.presentProductForm(productType: selectedProductType)
            }
        }
        let productTypesListPresenter = BottomSheetListSelectorPresenter(viewProperties: viewProperties, command: command)
        productTypesListPresenter.show(from: navigationController, sourceBarButtonItem: sourceView, arrowDirections: .up)
    }

    func presentProductForm(productType: ProductType) {
        let product = ProductFactory().createNewProduct(type: productType, siteID: siteID)
        let model = EditableProductModel(product: product)

        let currencyCode = CurrencySettings.shared.currencyCode
        let currency = CurrencySettings.shared.symbol(from: currencyCode)
        let productImageActionHandler = ProductImageActionHandler(siteID: product.siteID,
                                                                  product: model)
        let viewModel = ProductFormViewModel(product: model,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease3Enabled: true)
        let viewController = ProductFormViewController(viewModel: viewModel,
                                                       eventLogger: ProductFormEventLogger(),
                                                       productImageActionHandler: productImageActionHandler,
                                                       currency: currency,
                                                       presentationStyle: .navigationStack,
                                                       isEditProductsRelease3Enabled: true)
        let productFormNavigationController = WooNavigationController(rootViewController: viewController)
        navigationController.present(productFormNavigationController, animated: true) { [weak self] in
            self?.navigationController = productFormNavigationController
        }
//        navigationController.pushViewController(viewController, animated: true)
    }
}
