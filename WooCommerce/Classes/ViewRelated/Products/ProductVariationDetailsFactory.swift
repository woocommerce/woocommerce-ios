import UIKit
import Yosemite

struct ProductVariationDetailsFactory {
    /// Creates a view controller asynchronously that shows product variation details based on feature flags.
    /// - Parameters:
    ///   - productVariation: product variation model.
    ///   - parentProduct: the parent product of the product variation.
    ///   - presentationStyle: how the product variation details are presented.
    ///   - currencySettings: site currency settings.
    ///   - forceReadOnly: force the product variation details to be presented in read only mode.
    ///   - onCompletion: called when the view controller is created and ready for display.
    static func productVariationDetails(productVariation: ProductVariation,
                                        parentProduct: Product,
                                        presentationStyle: ProductFormPresentationStyle,
                                        currencySettings: CurrencySettings = ServiceLocator.currencySettings,
                                        forceReadOnly: Bool,
                                        onCompletion: @escaping (UIViewController) -> Void) {
        let vc = productVariationDetails(productVariation: productVariation,
                                         parentProduct: parentProduct,
                                         presentationStyle: presentationStyle,
                                         currencySettings: currencySettings,
                                         isEditProductsEnabled: forceReadOnly ? false: true,
                                         isEditProductsRelease3Enabled: ServiceLocator.featureFlagService.isFeatureFlagEnabled(.editProductsRelease3),
                                         isEditProductsRelease5Enabled: ServiceLocator.featureFlagService.isFeatureFlagEnabled(.editProductsRelease5))
        onCompletion(vc)
    }
}

private extension ProductVariationDetailsFactory {
    static func productVariationDetails(productVariation: ProductVariation,
                                        parentProduct: Product,
                                        presentationStyle: ProductFormPresentationStyle,
                                        currencySettings: CurrencySettings,
                                        isEditProductsEnabled: Bool,
                                        isEditProductsRelease3Enabled: Bool,
                                        isEditProductsRelease5Enabled: Bool) -> UIViewController {
        // TODO-2931: add support for readonly mode based on `isEditProductsEnabled`.
        let vc: UIViewController
        let productVariationModel = EditableProductVariationModel(productVariation: productVariation,
                                                                  allAttributes: parentProduct.attributes,
                                                                  parentProductSKU: parentProduct.sku)
        let productImageActionHandler = ProductImageActionHandler(siteID: productVariation.siteID,
                                                                  product: productVariationModel)

        let viewModel = ProductVariationFormViewModel(productVariation: productVariationModel,
                                                      allAttributes: parentProduct.attributes,
                                                      parentProductSKU: parentProduct.sku,
                                                      formType: .edit,
                                                      productImageActionHandler: productImageActionHandler)
        vc = ProductFormViewController(viewModel: viewModel,
                                       eventLogger: ProductFormEventLogger(),
                                       productImageActionHandler: productImageActionHandler,
                                       presentationStyle: presentationStyle,
                                       isEditProductsRelease3Enabled: isEditProductsRelease3Enabled)
        // Since the edit Product UI could hold local changes, disables the bottom bar (tab bar) to simplify app states.
        vc.hidesBottomBarWhenPushed = true
        return vc
    }
}
