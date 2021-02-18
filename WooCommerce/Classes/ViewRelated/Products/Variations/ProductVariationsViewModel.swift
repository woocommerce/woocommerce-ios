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

    /// Defines if the More Options button should be shown
    ///
    var showMoreButton: Bool {
        product.variations.isNotEmpty && isAddProductVariationsEnabled
    }

    init(product: Product,
         isAddProductVariationsEnabled: Bool) {
        self.product = product
        self.isAddProductVariationsEnabled = isAddProductVariationsEnabled
    }
}
