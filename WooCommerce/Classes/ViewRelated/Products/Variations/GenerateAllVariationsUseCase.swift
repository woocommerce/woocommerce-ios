import Foundation
import Yosemite

/// Generates and creates all variations needed for a product.
///
final class GenerateAllVariationsUseCase {

    /// Stores dependency. Needed to generate variations
    ///
    private let stores: StoresManager

    /// Analytics tracker.
    ///
    private let analytics: Analytics

    init(stores: StoresManager, analytics: Analytics = ServiceLocator.analytics) {
        self.stores = stores
        self.analytics = analytics
    }

    /// Generates all missing variations for a product. Up to 100 variations.
    /// Parameters:
    /// - `Product`: Product on which we will be creating the variations
    /// - `onStateChanged`: Closure invoked every time there is a significant state change in the generation process.
    ///
    func generateAllVariations(for product: Product, onStateChanged: @escaping (State) -> Void) {

        // Fetch Previous variations
        onStateChanged(.fetching)
        fetchAllVariations(of: product) { [analytics] result in
            switch result {
            case .success(let existingVariations):

                // Generate variations locally
                let variationsToGenerate = ProductVariationGenerator.generateVariations(for: product, excluding: existingVariations)

                // Guard for 100 variation limit
                guard variationsToGenerate.count <= 100 else {
                    analytics.track(event: .Variations.productVariationGenerationLimitReached(count: Int64(variationsToGenerate.count)))
                    return onStateChanged(.error(.tooManyVariations(variationCount: variationsToGenerate.count)))
                }

                // Guard for no variations to generate
                guard variationsToGenerate.count > 0 else {
                    return onStateChanged(.finished(false, product))
                }

                // Confirm generation with merchant
                onStateChanged(.confirmation(variationsToGenerate.count, { confirmed in

                    guard confirmed else {
                        return onStateChanged(.canceled)
                    }

                    analytics.track(event: .Variations.productVariationGenerationConfirmed(count: Int64(variationsToGenerate.count)))

                    // Create variations remotely
                    onStateChanged(.creating)
                    self.createVariationsRemotely(for: product, variations: variationsToGenerate) { result in
                        switch result {
                        case .success(let allVariations):

                            // Updates the current product with the up-to-date list of variations IDs.
                            // This is needed in order to reflect variations count changes back to other screens.
                            let updatedProduct = product.copy(variations: allVariations.map { $0.productVariationID })
                            onStateChanged(.finished(true, updatedProduct))

                        case .failure(let error):
                            onStateChanged(.error(error))
                        }
                    }
                }))

            case .failure(let error):
                onStateChanged(.error(.unableToFetchVariations))
                DDLogError("⛔️ Failed to fetch variations: \(error)")
                analytics.track(event: .Variations.productVariationGenerationFailure())
            }
        }
    }
}

// MARK: Helper Methods
//
private extension GenerateAllVariationsUseCase {
    /// Fetches all remote variations.
    ///
    private func fetchAllVariations(of product: Product, onCompletion: @escaping (Result<[ProductVariation], Error>) -> Void) {
        let action = ProductVariationAction.synchronizeAllProductVariations(siteID: product.siteID, productID: product.productID, onCompletion: onCompletion)
        stores.dispatch(action)
    }

    /// Creates the provided variations remotely.
    ///
    private func createVariationsRemotely(for product: Product,
                                          variations: [CreateProductVariation],
                                          onCompletion: @escaping (Result<[ProductVariation], GenerationError>) -> Void) {
        let action = ProductVariationAction.createProductVariations(siteID: product.siteID,
                                                                    productID: product.productID,
                                                                    productVariations: variations, onCompletion: { [analytics] result in
            switch result {
            case .success(let variations):
                onCompletion(.success(variations))
                analytics.track(event: .Variations.productVariationGenerationSuccess())

            case .failure(let error):
                onCompletion(.failure(.unableToCreateVariations))
                DDLogError("⛔️ Failed to create variations: \(error)")
                analytics.track(event: .Variations.productVariationGenerationFailure())
            }
        })
        stores.dispatch(action)
    }
}

// MARK: Definitions
///
extension GenerateAllVariationsUseCase {
    /// Type that represents the possible states while all variations are being created.
    ///
    enum State {
        /// State while previous variations are being fetched
        ///
        case fetching

        /// State to allow merchant to confirm the variation generation
        ///
        case confirmation(_ numberOfVariations: Int, _ onCompletion: (_ confirmed: Bool) -> Void)

        /// State while the variations are being created remotely
        ///
        case creating

        ///State when the merchant decides to not continue with the generation process.
        ///
        case canceled

        /// State when the the process is finished. `variationsCreated` indicates if  variations were created or not.
        /// `updatedProduct` contains the original product with the new generated variation ids in it's variations array.
        ///
        case finished(_ variationsCreated: Bool, _ updatedProduct: Product)

        /// Error state in any part of the process.
        ///
        case error(GenerationError)
    }

    /// Type to represent known generation errors
    ///
    enum GenerationError: LocalizedError, Equatable {
        case unableToFetchVariations
        case unableToCreateVariations
        case tooManyVariations(variationCount: Int)

        var errorTitle: String {
            switch self {
            case .unableToFetchVariations:
                return NSLocalizedString("Unable to fetch variations", comment: "Error title for when we can't fetch existing variations.")
            case .unableToCreateVariations:
                return NSLocalizedString("Unable to create variations", comment: "Error title for when we can't create variations remotely.")
            case .tooManyVariations:
                return NSLocalizedString("Generation limit exceeded", comment: "Error title for when there are too many variations to generate.")
            }
        }

        var errorDescription: String? {
            switch self {
            case .unableToFetchVariations:
                return NSLocalizedString("Something went wrong, please try again later.", comment: "Error message for when we can't fetch existing variations.")
            case .unableToCreateVariations:
                return NSLocalizedString("Something went wrong, please try again later.", comment: "Error message for when we can't create variations remotely")
            case .tooManyVariations(let variationCount):
                let format = NSLocalizedString(
                    "Currently creation is supported for 100 variations maximum. Generating variations for this product would create %d variations.",
                    comment: "Error description for when there are too many variations to generate."
                )
                return String.localizedStringWithFormat(format, variationCount)
            }
        }
    }
}
