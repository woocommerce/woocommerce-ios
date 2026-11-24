import UIKit
import Yosemite
import WooFoundation

struct ProductVariationDetailsFactory {
    /// Creates a view controller asynchronously that shows product variation details based on feature flags.
    /// - Parameters:
    ///   - productVariation: product variation model.
    ///   - parentProduct: the parent product of the product variation.
    ///   - presentationStyle: how the product variation details are presented.
    ///   - currencySettings: site currency settings.
    ///   - forceReadOnly: force the product variation details to be presented in read only mode.
    ///   - onCompletion: called when the view controller is created and ready for display.
    @MainActor
    static func productVariationDetails(productVariation: ProductVariation,
                                        parentProduct: Product,
                                        presentationStyle: ProductFormPresentationStyle,
                                        currencySettings: CurrencySettings = ServiceLocator.currencySettings,
                                        forceReadOnly: Bool,
                                        productImageUploader: ProductImageUploaderProtocol = ServiceLocator.productImageUploader,
                                        onCompletion: @escaping (UIViewController) -> Void) {
        productVariationDetails(productVariation: productVariation,
                                parentProduct: parentProduct,
                                presentationStyle: presentationStyle,
                                formType: forceReadOnly ? .readonly: .edit,
                                eventLogger: ProductFormEventLogger(),
                                currencySettings: currencySettings,
                                productImageUploader: productImageUploader,
                                onCompletion: onCompletion)
    }

    /// Creates a product variation details view controller for a specific form type.
    @MainActor
    static func productVariationDetails(productVariation: ProductVariation,
                                        parentProduct: Product,
                                        presentationStyle: ProductFormPresentationStyle,
                                        formType: ProductFormType,
                                        eventLogger: ProductFormEventLoggerProtocol,
                                        currencySettings: CurrencySettings = ServiceLocator.currencySettings,
                                        productImageUploader: ProductImageUploaderProtocol = ServiceLocator.productImageUploader,
                                        onVariationDeletion: @escaping (ProductVariation) -> Void = { _ in },
                                        onCompletion: @escaping (UIViewController) -> Void) {
        let productVariationModel = EditableProductVariationModel(productVariation: productVariation,
                                                                  parentProductType: parentProduct.productType,
                                                                  allAttributes: parentProduct.attributesForVariations,
                                                                  parentProductSKU: parentProduct.sku,
                                                                  parentProductDisablesQuantityRules: parentProduct.combineVariationQuantities)
        let productImageActionHandler = productImageUploader
            .actionHandler(key: .init(siteID: productVariation.siteID,
                                      productOrVariationID: .variation(productID: productVariation.productID, variationID: productVariation.productVariationID),
                                      isLocalID: !productVariationModel.existsRemotely),
                           originalStatuses: productVariationModel.imageStatuses)
        let viewModel = ProductVariationFormViewModel(productVariation: productVariationModel,
                                                      allAttributes: parentProduct.attributesForVariations,
                                                      parentProductSKU: parentProduct.sku,
                                                      parentProductDisablesQuantityRules: parentProduct.combineVariationQuantities,
                                                      formType: formType,
                                                      productImageActionHandler: productImageActionHandler)
        viewModel.onVariationDeletion = onVariationDeletion
        let viewController = ProductFormViewController(viewModel: viewModel,
                                                       eventLogger: eventLogger,
                                                       productImageActionHandler: productImageActionHandler,
                                                       currency: currencySettings.symbol(from: currencySettings.currencyCode),
                                                       presentationStyle: presentationStyle,
                                                       productImageUploader: productImageUploader,
                                                       onDuplicateCompletion: { _, _ in })
        // Since the edit Product UI could hold local changes, disables the bottom bar (tab bar) to simplify app states.
        viewController.hidesBottomBarWhenPushed = true
        onCompletion(viewController)
    }
}
