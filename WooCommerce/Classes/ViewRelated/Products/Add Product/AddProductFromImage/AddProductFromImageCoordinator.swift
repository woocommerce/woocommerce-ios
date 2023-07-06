import Photos
import UIKit
import Yosemite
import WooFoundation

/// Controls navigation for the flow to add a product from an image.
final class AddProductFromImageCoordinator: Coordinator {
    let navigationController: UINavigationController

    /// Navigation controller for the product creation form.
    private var formNavigationController: UINavigationController?

    private let siteID: Int64
    private let productImageUploader: ProductImageUploaderProtocol
    private let productImageLoader: ProductUIImageLoader

    /// Invoked when a new product is saved remotely.
    private let onProductCreated: (Product) -> Void

    init(siteID: Int64,
         sourceNavigationController: UINavigationController,
         productImageUploader: ProductImageUploaderProtocol = ServiceLocator.productImageUploader,
         productImageLoader: ProductUIImageLoader = DefaultProductUIImageLoader(phAssetImageLoaderProvider: { PHImageManager.default() }),
         onProductCreated: @escaping (Product) -> Void) {
        self.siteID = siteID
        self.navigationController = sourceNavigationController
        self.productImageUploader = productImageUploader
        self.productImageLoader = productImageLoader
        self.onProductCreated = onProductCreated
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func start() {
        let addProductFromImage = AddProductFromImageHostingController(siteID: siteID,
                                                                       completion: { [weak self] data in
            self?.navigationController.dismiss(animated: true) { [weak self] in
                guard let self else { return }
                guard let product = self.createProduct(name: data.name, description: data.description) else {
                    return
                }
                self.showProduct(product)
            }
        })
        let formNavigationController = UINavigationController(rootViewController: addProductFromImage)
        self.formNavigationController = formNavigationController
        navigationController.present(formNavigationController, animated: true)
    }
}

private extension AddProductFromImageCoordinator {
    func createProduct(name: String, description: String?) -> Product? {
        guard let product = ProductFactory().createNewProduct(type: .simple,
                                                              isVirtual: false,
                                                              siteID: siteID)?
            .copy(name: name,
                  fullDescription: description) else {
            return nil
        }
        return product
    }

    /// Shows a product in the current navigation stack.
    func showProduct(_ product: Product) {
        let model = EditableProductModel(product: product)
        let currencyCode = ServiceLocator.currencySettings.currencyCode
        let currency = ServiceLocator.currencySettings.symbol(from: currencyCode)
        let productImageActionHandler = productImageUploader
            .actionHandler(key: .init(siteID: product.siteID,
                                      productOrVariationID: .product(id: model.productID),
                                      isLocalID: true),
                           originalStatuses: [])
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .add,
                                             productImageActionHandler: productImageActionHandler)
        viewModel.onProductCreated = { [weak self] product in
            guard let self else { return }
            self.onProductCreated(product)
        }
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
