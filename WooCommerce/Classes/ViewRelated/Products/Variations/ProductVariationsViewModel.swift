import Foundation
import Yosemite

/// Provides view data for Product Variations.
///
final class ProductVariationsViewModel {

    /// Stores dependency. Needed to generate variations
    ///
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
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
        product.variations.isEmpty || product.attributesForVariations.isEmpty
    }

    /// Defines if the More Options button should be shown
    ///
    func shouldShowMoreButton(for product: Product) -> Bool {
        product.attributesForVariations.isNotEmpty
    }
}
