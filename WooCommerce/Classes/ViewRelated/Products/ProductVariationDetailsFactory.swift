import UIKit
import Yosemite
import WooFoundation

@MainActor
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
                                        productImageUploader: ProductImageUploaderProtocol = ServiceLocator.productImageUploader,
                                        onCompletion: @escaping (UIViewController) -> Void) {
        let vc = productVariationDetails(productVariation: productVariation,
                                         parentProduct: parentProduct,
                                         presentationStyle: presentationStyle,
                                         currencySettings: currencySettings,
                                         isEditProductsEnabled: forceReadOnly ? false: true,
                                         productImageUploader: productImageUploader)
        onCompletion(vc)
    }
}

private extension ProductVariationDetailsFactory {
    static func productVariationDetails(productVariation: ProductVariation,
                                        parentProduct: Product,
                                        presentationStyle: ProductFormPresentationStyle,
                                        currencySettings: CurrencySettings,
                                        isEditProductsEnabled: Bool,
                                        productImageUploader: ProductImageUploaderProtocol) -> UIViewController {
        let vc: UIViewController
        let productVariationModel = EditableProductVariationModel(productVariation: productVariation,
                                                                  parentProductType: parentProduct.productType,
                                                                  allAttributes: parentProduct.attributes,
                                                                  parentProductSKU: parentProduct.sku,
                                                                  parentProductDisablesQuantityRules: parentProduct.combineVariationQuantities)
        let productImageActionHandler = productImageUploader
            .actionHandler(key: .init(siteID: productVariation.siteID,
                                      productOrVariationID: .variation(productID: productVariation.productID, variationID: productVariation.productVariationID),
                                      isLocalID: !productVariationModel.existsRemotely),
                           originalStatuses: productVariationModel.imageStatuses)
        let formType: ProductFormType = isEditProductsEnabled ? .edit: .readonly
        let viewModel = ProductVariationFormViewModel(productVariation: productVariationModel,
                                                      allAttributes: parentProduct.attributes,
                                                      parentProductSKU: parentProduct.sku,
                                                      parentProductDisablesQuantityRules: parentProduct.combineVariationQuantities,
                                                      formType: formType,
                                                      productImageActionHandler: productImageActionHandler)
        vc = ProductFormViewController(viewModel: viewModel,
                                       eventLogger: ProductFormEventLogger(),
                                       productImageActionHandler: productImageActionHandler,
                                       presentationStyle: presentationStyle)
        // Since the edit Product UI could hold local changes, disables the bottom bar (tab bar) to simplify app states.
        vc.hidesBottomBarWhenPushed = true
        return vc
    }
}
