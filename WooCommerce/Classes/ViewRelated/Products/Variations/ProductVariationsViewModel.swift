import Foundation
import Yosemite

/// Provides view data for Product Variations.
///
final class ProductVariationsViewModel {

    /// Main product dependency.
    ///
    private let product: Product

    /// Defines if the Add Product Variations feature is enabled
    ///
    private let isAddProductVariationsEnabled: Bool

    /// Stores dependency. Needed to generate variations
    ///
    private let stores: StoresManager

    /// Defines if the More Options button should be shown
    ///
    var showMoreButton: Bool {
        product.variations.isNotEmpty && isAddProductVariationsEnabled
    }

    init(product: Product, isAddProductVariationsEnabled: Bool, stores: StoresManager = ServiceLocator.stores) {
        self.product = product
        self.isAddProductVariationsEnabled = isAddProductVariationsEnabled
        self.stores = stores
    }

    /// Generates a variation in the host site using the product attributes
    ///
    func generateVariation(onCompletion: @escaping (Result<Product, Error>) -> Void) {
        let useCase = GenerateVariationUseCase(product: product, stores: stores)
        useCase.generateVariation(onCompletion: onCompletion)
    }

    /// Defines the empty state screen visibility
    /// TODO: This method should turned into a computed variable, once the `ViewController` is refactored to use `MMVM`.
    ///
    func shouldShowEmptyState(for newProduct: Product) -> Bool {
        newProduct.variations.isEmpty || newProduct.attributes.isEmpty
    }
}
