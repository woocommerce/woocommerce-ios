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
    ///
    func generateAllVariations(for product: Product) {
        let action = ProductVariationAction.synchronizeAllProductVariations(siteID: product.siteID, productID: product.productID) { result in
            // TODO: Fetch this via a results controller
            let existingVariations = ServiceLocator.storageManager.viewStorage.loadProductVariations(siteID: product.siteID, productID: product.productID)?
                .map {
                    $0.toReadOnly()
                } ?? []

            // TEMP
            let variationsToGenerate = ProductVariationGenerator.generateVariations(for: product, excluding: existingVariations)
            print("Variations to Generate: \(variationsToGenerate.count)")

        }
        stores.dispatch(action)

        // TODO:
        // - Alert if there are more than 100 variations to create
        // - Create variations remotely
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
}
