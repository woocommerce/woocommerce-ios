import Foundation
import Yosemite

/// Provides view data for Product Variations.
///
final class ProductVariationsViewModel {

    /// Stores dependency. Needed to generate variations
    ///
    private let stores: StoresManager

    /// Stores the form type to use in the subsequent screens. EG: ProductVariationForm
    ///
    private(set) var formType: ProductFormType

    init(stores: StoresManager = ServiceLocator.stores, formType: ProductFormType) {
        self.stores = stores
        self.formType = formType
    }

    /// Generates a variation in the host site using the product attributes
    ///
    func generateVariation(for product: Product, onCompletion: @escaping (Result<(Product, ProductVariation), Error>) -> Void) {
        let useCase = GenerateVariationUseCase(product: product, stores: stores)
        useCase.generateVariation(onCompletion: onCompletion)
    }

    /// Generates all missing variations for a product. Up to 100 variations.
    /// Parameters:
    /// - `Product`: Product on which we will be creating the variations
    /// - `onStateChanged`: Closure invoked every time there is a significant state change in the generation process.
    ///
    func generateAllVariations(for product: Product, onStateChanged: @escaping (GenerateAllVariationsUseCase.State) -> Void) {
        let useCase = GenerateAllVariationsUseCase(stores: stores)
        useCase.generateAllVariations(for: product, onStateChanged: onStateChanged)
    }

    /// Updates the internal `formType` to `edit` if  the given product exists remotely and previous formType was `.add`
    ///
    func updatedFormTypeIfNeeded(newProduct: Product) {
        guard formType == .add, newProduct.existsRemotely else {
            return
        }
        formType = .edit
    }
}

/// TODO: This functions need to be converted to computed variables, once the `ViewController` is refactored to use `MMVM`.
extension ProductVariationsViewModel {
    /// Defines the empty state screen visibility
    ///
    func shouldShowEmptyState(for product: Product) -> Bool {
        product.variations.isEmpty || product.attributesForVariations.isEmpty
    }

    /// Defines if empty state screen should show guide for creating attributes
    ///
    func shouldShowAttributeGuide(for product: Product) -> Bool {
        product.attributesForVariations.isEmpty
    }

    /// Defines if screen should show the options to generate new variations.
    ///
    /// Generating variations is currently disabled for variable subscription products.
    ///
    func shouldAllowGeneration(for product: Product) -> Bool {
        product.productType != .variableSubscription
    }

    /// Defines if screen should allow bulk editing.
    ///
    /// Bulk editing is currently disabled for variable subscription products.
    ///
    func shouldAllowBulkEditing(for product: Product) -> Bool {
        product.productType != .variableSubscription
    }
}
