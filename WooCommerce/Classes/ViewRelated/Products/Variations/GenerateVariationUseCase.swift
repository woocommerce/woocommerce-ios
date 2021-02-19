import Foundation
import Yosemite

/// Generates a new variation for a product, with no price and no options selected
///
final class GenerateVariationUseCase {

    /// Main product dependency
    ///
    private let product: Product

    /// Stores to dispatch the generate variation action.
    ///
    private let stores: StoresManager

    init(product: Product, stores: StoresManager = ServiceLocator.stores) {
        self.product = product
        self.stores = stores
    }

    /// Generates a variation in the host site using the product attributes
    ///
    func generateVariation(onCompletion: @escaping (Result<Product, Error>) -> Void) {
        let action = ProductVariationAction.createProductVariation(siteID: product.siteID,
                                                                   productID: product.productID,
                                                                   newVariation: createVariationParameter()) { [product] result in

            // Convert the variationResult into a productResult by appending the variationID to the variations array
            let productResult = result.map { variation in
                product.copy(variations: product.variations + [variation.productVariationID])
            }

            onCompletion(productResult)
        }
        stores.dispatch(action)
    }

    /// Returns a `CreateProductVariation` type with no price and no options selected for any of it's attributes.
    ///
    private func createVariationParameter() -> CreateProductVariation {
        let attributes = product.attributes.map { ProductVariationAttribute(id: $0.attributeID, name: $0.name, option: "") }
        return CreateProductVariation(regularPrice: "", attributes: attributes)
    }
}
