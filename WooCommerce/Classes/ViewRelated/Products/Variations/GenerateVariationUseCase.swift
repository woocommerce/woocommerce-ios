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

    /// Track the variation generation result
    ///
    private let analytics: Analytics

    init(product: Product, stores: StoresManager = ServiceLocator.stores, analytics: Analytics = ServiceLocator.analytics) {
        self.product = product
        self.stores = stores
        self.analytics = analytics
    }

    /// Generates a variation in the host site using the product attributes
    ///
    func generateVariation(onCompletion: @escaping (Result<Product, Error>) -> Void) {

        let startDate = Date()
        analytics.track(event: WooAnalyticsEvent.Variations.createVariation(productID: product.productID))

        let action = ProductVariationAction.createProductVariation(siteID: product.siteID,
                                                                   productID: product.productID,
                                                                   newVariation: createVariationParameter()) { [product, analytics] result in

            // Convert the variationResult into a productResult by appending the variationID to the variations array
            let productResult = result.map { variation in
                product.copy(variations: product.variations + [variation.productVariationID])
            }

            onCompletion(productResult)

            // Track generation result
            let timeElapsed = Date().timeIntervalSince(startDate)
            switch result {
            case .success:
                analytics.track(event: WooAnalyticsEvent.Variations.createVariationSuccess(productID: product.productID, time: timeElapsed))
            case let .failure(error):
                analytics.track(event: WooAnalyticsEvent.Variations.createVariationFail(productID: product.productID,
                                                                                        time: timeElapsed,
                                                                                        error: error))
            }
        }
        stores.dispatch(action)
    }

    /// Returns a `CreateProductVariation` type with no price and no options selected for any of it's attributes.
    ///
    private func createVariationParameter() -> CreateProductVariation {
        let attributes = product.attributesForVariations.map { ProductVariationAttribute(id: $0.attributeID, name: $0.name, option: "") }
        return CreateProductVariation(regularPrice: "", attributes: attributes)
    }
}
