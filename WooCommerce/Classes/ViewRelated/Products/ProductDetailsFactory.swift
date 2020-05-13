import UIKit
import Yosemite

struct ProductDetailsFactory {
    /// Creates a product details view controller asynchronously based on the app settings.
    /// - Parameters:
    ///   - product: product model.
    ///   - presentationStyle: how the product details are presented.
    ///   - currencySettings: site currency settings.
    ///   - featureFlagService: where edit product feature flags are read.
    ///   - onCompletion: called when the view controller is created and ready for display.
    static func productDetails(product: Product,
                               presentationStyle: ProductFormViewController.PresentationStyle,
                               currencySettings: CurrencySettings = CurrencySettings.shared,
                               featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
                               onCompletion: @escaping (UIViewController) -> Void) {
        let isEditProductsEnabled = featureFlagService.isFeatureFlagEnabled(.editProducts)
        if product.productType == .simple && isEditProductsEnabled {
            let action = AppSettingsAction.loadProductsFeatureSwitch { isEditProductsRelease2Enabled in
                let vc = productDetails(product: product,
                                        presentationStyle: presentationStyle,
                                        currencySettings: currencySettings,
                                        isEditProductsEnabled: isEditProductsEnabled,
                                        isEditProductsRelease2Enabled: isEditProductsRelease2Enabled,
                                        isEditProductsRelease3Enabled: featureFlagService.isFeatureFlagEnabled(.editProductsRelease3))
                onCompletion(vc)
            }
            ServiceLocator.stores.dispatch(action)
        } else {
            let vc = productDetails(product: product,
                                    presentationStyle: presentationStyle,
                                    currencySettings: currencySettings,
                                    isEditProductsEnabled: false,
                                    isEditProductsRelease2Enabled: false,
                                    isEditProductsRelease3Enabled: false)
            onCompletion(vc)
        }
    }
}

private extension ProductDetailsFactory {
    static func productDetails(product: Product,
                               presentationStyle: ProductFormViewController.PresentationStyle,
                               currencySettings: CurrencySettings,
                               isEditProductsEnabled: Bool,
                               isEditProductsRelease2Enabled: Bool,
                               isEditProductsRelease3Enabled: Bool) -> UIViewController {
        let currencyCode = currencySettings.currencyCode
        let currency = currencySettings.symbol(from: currencyCode)
        let vc: UIViewController
        if isEditProductsEnabled {
            vc = ProductFormViewController(product: product,
                                           currency: currency,
                                           presentationStyle: presentationStyle,
                                           isEditProductsRelease2Enabled: isEditProductsRelease2Enabled,
                                           isEditProductsRelease3Enabled: isEditProductsRelease3Enabled)
            // Since the edit Product UI could hold local changes, disables the bottom bar (tab bar) to simplify app states.
            vc.hidesBottomBarWhenPushed = true
        } else {
            let viewModel = ProductDetailsViewModel(product: product, currency: currency)
            vc = ProductDetailsViewController(viewModel: viewModel)
        }
        return vc
    }
}
