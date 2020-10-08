import Yosemite

/// Encapsulates the async logic for loading product variation and related data (its parent product) for UI display.
final class ProductVariationLoadUseCase {
    /// A wrapper of product variation and its parent product.
    struct ResultData: Equatable {
        let variation: ProductVariation
        let parentProduct: Product
    }
    typealias Completion = (Result<ResultData, AnyError>) -> Void

    private let siteID: Int64
    private let stores: StoresManager

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    /// Fetches `ProductVariation` and its parent `Product` remotely.
    ///
    /// - Parameters:
    ///   - productID: variation's parent product ID.
    ///   - variationID: variation ID.
    ///   - onCompletion: called when loading for `ProductVariation` and its parent `Product` completes.
    func loadProductVariation(productID: Int64, variationID: Int64, onCompletion: @escaping Completion) {
        let group = DispatchGroup()

        var productVariationResult: Result<ProductVariation, Error>?
        var parentProductResult: Result<Product, Error>?

        group.enter()
        let productVariationAction = ProductVariationAction.retrieveProductVariation(siteID: siteID,
                                                                                     productID: productID,
                                                                                     variationID: variationID) { result in
                                                                                        productVariationResult = result
                                                                                        group.leave()
        }
        stores.dispatch(productVariationAction)

        group.enter()
        let productAction = ProductAction.retrieveProduct(siteID: siteID, productID: productID) { result in
            parentProductResult = result
            group.leave()
        }
        stores.dispatch(productAction)

        group.notify(queue: .main) {
            guard let parentProductResult = parentProductResult, let productVariationResult = productVariationResult else {
                assertionFailure("Unexpected nil result after updating product and password remotely")
                onCompletion(.failure(.init(ProductVariationLoadError.unexpected)))
                return
            }

            do {
                let parentProduct = try parentProductResult.get()
                let variation = try productVariationResult.get()
                onCompletion(.success(ResultData(variation: variation, parentProduct: parentProduct)))
            } catch {
                let errors: [Error] = [productVariationResult.failure, parentProductResult.failure].compactMap { $0 }
                guard let error = errors.first else {
                    assertionFailure("""
                        Unexpected error with variation result: \(productVariationResult)\nparent product result: \(parentProductResult)
                        """)
                    onCompletion(.failure(.init(ProductVariationLoadError.unexpected)))
                    return
                }
                onCompletion(.failure(.init(error)))
            }
        }
    }
}
