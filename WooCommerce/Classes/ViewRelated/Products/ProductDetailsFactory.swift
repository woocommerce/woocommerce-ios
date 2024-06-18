import UIKit
import Yosemite
import WooFoundation

struct ProductDetailsFactory {
    /// Creates a product details view controller asynchronously based on the app settings.
    /// - Parameters:
    ///   - product: product model.
    ///   - presentationStyle: how the product details are presented.
    ///   - currencySettings: site currency settings.
    ///   - forceReadOnly: force the product detail to be presented in read only mode
    ///   - onDeleteCompletion: called when the product deletion completes in the product form.
    ///   - onCompletion: called when the view controller is created and ready for display.
    @MainActor
    static func productDetails(product: Product,
                               presentationStyle: ProductFormPresentationStyle,
                               currencySettings: CurrencySettings = ServiceLocator.currencySettings,
                               forceReadOnly: Bool,
                               productImageUploader: ProductImageUploaderProtocol = ServiceLocator.productImageUploader,
                               onDeleteCompletion: @escaping () -> Void = {},
                               onCompletion: @escaping (UIViewController) -> Void) {
        let vc = productDetails(product: product,
                                presentationStyle: presentationStyle,
                                currencySettings: currencySettings,
                                isEditProductsEnabled: forceReadOnly ? false: true,
                                productImageUploader: productImageUploader,
                                onDeleteCompletion: onDeleteCompletion)
        onCompletion(vc)
    }
}

private extension ProductDetailsFactory {
    @MainActor
    static func productDetails(product: Product,
                               presentationStyle: ProductFormPresentationStyle,
                               currencySettings: CurrencySettings,
                               isEditProductsEnabled: Bool,
                               productImageUploader: ProductImageUploaderProtocol,
                               onDeleteCompletion: @escaping () -> Void) -> UIViewController {
        let vc: UIViewController
        let productModel = EditableProductModel(product: product)
        let productImageActionHandler = productImageUploader
            .actionHandler(key: .init(siteID: product.siteID,
                                      productOrVariationID: .product(id: productModel.productID),
                                      isLocalID: false),
                           originalStatuses: productModel.imageStatuses)
        let formType: ProductFormType = isEditProductsEnabled ? .edit: .readonly
        let viewModel = ProductFormViewModel(product: productModel,
                                             formType: formType,
                                             productImageActionHandler: productImageActionHandler)
        vc = ProductFormViewController(viewModel: viewModel,
                                       eventLogger: ProductFormEventLogger(),
                                       productImageActionHandler: productImageActionHandler,
                                       presentationStyle: presentationStyle,
                                       onDeleteCompletion: onDeleteCompletion)
        // Since the edit Product UI could hold local changes, disables the bottom bar (tab bar) to simplify app states.
        vc.hidesBottomBarWhenPushed = true
        return vc
    }
}
