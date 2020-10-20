import UIKit
import Yosemite

struct ProductDetailsFactory {
    /// Creates a product details view controller asynchronously based on the app settings.
    /// - Parameters:
    ///   - product: product model.
    ///   - presentationStyle: how the product details are presented.
    ///   - currencySettings: site currency settings.
    ///   - stores: where the Products feature switch value can be read.
    ///   - forceReadOnly: force the product detail to be presented in read only mode
    ///   - onCompletion: called when the view controller is created and ready for display.
    static func productDetails(product: Product,
                               presentationStyle: ProductFormPresentationStyle,
                               currencySettings: CurrencySettings = ServiceLocator.currencySettings,
                               stores: StoresManager = ServiceLocator.stores,
                               forceReadOnly: Bool,
                               onCompletion: @escaping (UIViewController) -> Void) {
        let vc = productDetails(product: product,
                                presentationStyle: presentationStyle,
                                currencySettings: currencySettings,
                                isEditProductsEnabled: forceReadOnly ? false: true,
                                isEditProductsRelease5Enabled: ServiceLocator.featureFlagService.isFeatureFlagEnabled(.editProductsRelease5))
        onCompletion(vc)
    }
}

private extension ProductDetailsFactory {
    static func productDetails(product: Product,
                               presentationStyle: ProductFormPresentationStyle,
                               currencySettings: CurrencySettings,
                               isEditProductsEnabled: Bool,
                               isEditProductsRelease5Enabled: Bool) -> UIViewController {
        let vc: UIViewController
        let productModel = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: product.siteID,
                                                                  product: productModel)
        let formType: ProductFormType = isEditProductsEnabled ? .edit: .readonly
        let viewModel = ProductFormViewModel(product: productModel,
                                             formType: formType,
                                             productImageActionHandler: productImageActionHandler,
                                             isEditProductsRelease5Enabled: isEditProductsRelease5Enabled)
        vc = ProductFormViewController(viewModel: viewModel,
                                       eventLogger: ProductFormEventLogger(),
                                       productImageActionHandler: productImageActionHandler,
                                       presentationStyle: presentationStyle,
                                       isEditProductsRelease5Enabled: isEditProductsRelease5Enabled)
        // Since the edit Product UI could hold local changes, disables the bottom bar (tab bar) to simplify app states.
        vc.hidesBottomBarWhenPushed = true
        return vc
    }
}
