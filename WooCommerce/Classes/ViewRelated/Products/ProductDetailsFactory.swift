import UIKit
import Yosemite

struct ProductDetailsFactory {
    /// Creates a product details view controller asynchronously based on the app settings.
    /// - Parameters:
    ///   - product: product model.
    ///   - presentationStyle: how the product details are presented.
    ///   - currencySettings: site currency settings.
    ///   - stores: where the Products feature switch value can be read.
    ///   - onCompletion: called when the view controller is created and ready for display.
    static func productDetails(product: Product,
                               presentationStyle: ProductFormPresentationStyle,
                               currencySettings: CurrencySettings = ServiceLocator.currencySettings,
                               stores: StoresManager = ServiceLocator.stores,
                               onCompletion: @escaping (UIViewController) -> Void) {
        let action = AppSettingsAction.loadProductsFeatureSwitch { isFeatureSwitchOn in
            let isEditProductsEnabled: Bool
            switch product.productType {
            case .simple:
                isEditProductsEnabled = true
            default:
                isEditProductsEnabled = isFeatureSwitchOn
            }

            let vc = productDetails(product: product,
                                    presentationStyle: presentationStyle,
                                    currencySettings: currencySettings,
                                    isEditProductsEnabled: isEditProductsEnabled,
                                    isEditProductsRelease3Enabled: isFeatureSwitchOn)
            onCompletion(vc)
        }
        stores.dispatch(action)
    }
}

private extension ProductDetailsFactory {
    static func productDetails(product: Product,
                               presentationStyle: ProductFormPresentationStyle,
                               currencySettings: CurrencySettings,
                               isEditProductsEnabled: Bool,
                               isEditProductsRelease3Enabled: Bool) -> UIViewController {
        let vc: UIViewController
        let productModel = EditableProductModel(product: product)
        let productImageActionHandler = ProductImageActionHandler(siteID: product.siteID,
                                                                  product: productModel)
        if isEditProductsEnabled {
            let viewModel = ProductFormViewModel(product: productModel,
                                                 formType: .edit,
                                                 productImageActionHandler: productImageActionHandler,
                                                 isEditProductsRelease3Enabled: isEditProductsRelease3Enabled)
            vc = ProductFormViewController(viewModel: viewModel,
                                           eventLogger: ProductFormEventLogger(),
                                           productImageActionHandler: productImageActionHandler,
                                           presentationStyle: presentationStyle,
                                           isEditProductsRelease3Enabled: isEditProductsRelease3Enabled)
            // Since the edit Product UI could hold local changes, disables the bottom bar (tab bar) to simplify app states.
            vc.hidesBottomBarWhenPushed = true
        } else {
            let viewModel = ProductDetailsViewModel(product: product)
            vc = ProductDetailsViewController(viewModel: viewModel)
        }
        return vc
    }
}
