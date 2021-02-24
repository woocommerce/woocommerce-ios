import Foundation
import Yosemite

/// Provides view data for Product Variations.
///
final class ProductVariationsViewModel {

    /// Defines if the Add Product Variations feature is enabled
    ///
    private let isAddProductVariationsEnabled: Bool

    /// Stores dependency. Needed to generate variations
    ///
    private let stores: StoresManager

    init(isAddProductVariationsEnabled: Bool, stores: StoresManager = ServiceLocator.stores) {
        self.isAddProductVariationsEnabled = isAddProductVariationsEnabled
        self.stores = stores
    }

    /// Generates a variation in the host site using the product attributes
    ///
    func generateVariation(for product: Product, onCompletion: @escaping (Result<Product, Error>) -> Void) {
        let useCase = GenerateVariationUseCase(product: product, stores: stores)
        useCase.generateVariation(onCompletion: onCompletion)
    }
}

/// TODO: This functions need to be converted to computed variables, once the `ViewController` is refactored to use `MMVM`.
extension ProductVariationsViewModel {
    /// Defines the empty state screen visibility
    ///
    func shouldShowEmptyState(for product: Product) -> Bool {
        product.variations.isEmpty || product.attributes.isEmpty
    }

    /// Defines if the More Options button should be shown
    ///
    func showMoreButton(for product: Product) -> Bool {
        product.variations.isNotEmpty && product.attributes.isNotEmpty && isAddProductVariationsEnabled
    }
}
