import UIKit
import Yosemite
import WooFoundation
import protocol Experiments.FeatureFlagService

struct ProductDetailsFactory {
    /// Creates a product details view controller asynchronously based on the app settings.
    /// - Parameters:
    ///   - product: product model.
    ///   - presentationStyle: how the product details are presented.
    ///   - currencySettings: site currency settings.
    ///   - forceReadOnly: force the product detail to be presented in read only mode
    ///   - onDeleteCompletion: called when the product deletion completes in the product form.
    ///   - onDuplicateCompletion: called with the new duplicate when a product duplication completes in the product form.
    @MainActor
    static func productDetails(product: Product,
                               presentationStyle: ProductFormPresentationStyle,
                               currencySettings: CurrencySettings = ServiceLocator.currencySettings,
                               forceReadOnly: Bool,
                               productImageUploader: ProductImageUploaderProtocol = ServiceLocator.productImageUploader,
                               onDeleteCompletion: @escaping () -> Void = {},
                               onDuplicateCompletion: @escaping ProductDuplicateNavigationHandler) -> UIViewController {
        productDetails(product: product,
                       presentationStyle: presentationStyle,
                       formType: forceReadOnly ? .readonly: .edit,
                       currencySettings: currencySettings,
                       productImageUploader: productImageUploader,
                       onDeleteCompletion: onDeleteCompletion,
                       onDuplicateCompletion: onDuplicateCompletion)
    }

    /// Creates a product details view controller for a specific form type.
    @MainActor
    static func productDetails(product: Product,
                               presentationStyle: ProductFormPresentationStyle,
                               formType: ProductFormType,
                               isAIContent: Bool = false,
                               isLocalProduct: Bool = false,
                               currencySettings: CurrencySettings = ServiceLocator.currencySettings,
                               productImageUploader: ProductImageUploaderProtocol = ServiceLocator.productImageUploader,
                               featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
                               onProductCreated: @escaping (_ product: Product, _ canShareProduct: Bool) -> Void = { _, _ in },
                               onDeleteCompletion: @escaping () -> Void = {},
                               onDuplicateCompletion: @escaping ProductDuplicateNavigationHandler) -> UIViewController {
        let productModel = EditableProductModel(product: product)
        let productImageActionHandler = productImageUploader
            .actionHandler(key: .init(siteID: product.siteID,
                                      productOrVariationID: .product(id: productModel.productID),
                                      isLocalID: isLocalProduct),
                           originalStatuses: productModel.imageStatuses)
        let viewModel = ProductFormViewModel(product: productModel,
                                             formType: formType,
                                             productImageActionHandler: productImageActionHandler)
        viewModel.onProductCreated = { [weak viewModel] product in
            guard let viewModel else {
                return
            }
            onProductCreated(product, viewModel.canShareProduct())
        }
        let viewController = ProductFormViewController(viewModel: viewModel,
                                                       isAIContent: isAIContent,
                                                       eventLogger: ProductFormEventLogger(),
                                                       productImageActionHandler: productImageActionHandler,
                                                       currency: currencySettings.symbol(from: currencySettings.currencyCode),
                                                       presentationStyle: presentationStyle,
                                                       productImageUploader: productImageUploader,
                                                       usesStoreRenderer: featureFlagService.usesStoreDesignSystem && formType != .add,
                                                       onDeleteCompletion: onDeleteCompletion,
                                                       onDuplicateCompletion: onDuplicateCompletion)
        // Since the edit Product UI could hold local changes, disables the bottom bar (tab bar) to simplify app states.
        viewController.hidesBottomBarWhenPushed = true
        return viewController
    }
}
