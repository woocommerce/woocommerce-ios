import Foundation
import Yosemite


// MARK: - Product details view model
//
final class ProductDetailsViewModel {

    /// Yosemite.Product
    ///
    private let product: Product

    // MARK: - Intializers

    /// Designated initializer.
    ///
    init(product: Product) {
        self.product = product
    }
}
