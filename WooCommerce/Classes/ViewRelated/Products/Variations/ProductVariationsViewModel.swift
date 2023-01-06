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
    /// Parameters:
    /// - `Product`: Product on which we will be creating the variations
    /// - `onStateChanged`: Closure invoked every time there is a significant state change in the generation process.
    ///
    func generateAllVariations(for product: Product, onStateChanged: @escaping (GenerationState) -> Void) {

        // Fetch Previous variations
        onStateChanged(.fetching)
        fetchAllVariations(of: product) { [weak self] result in
            switch result {
            case .success(let existingVariations):

                // Generate variations locally
                let variationsToGenerate = ProductVariationGenerator.generateVariations(for: product, excluding: existingVariations)

                // Guard for 100 variation limit
                guard variationsToGenerate.count <= 100 else {
                    return onStateChanged(.error(.tooManyVariations(variationCount: variationsToGenerate.count)))
                }

                // Guard for no variations to generate
                guard variationsToGenerate.count > 0 else {
                    return onStateChanged(.finished(false))
                }

                // Confirm generation with merchant
                onStateChanged(.confirmation(variationsToGenerate.count, { confirmed in

                    guard confirmed else {
                        return onStateChanged(.canceled)
                    }

                    // Create variations remotely
                    onStateChanged(.creating)
                    self?.createVariationsRemotely(for: product, variations: variationsToGenerate) { result in
                        switch result {
                        case .success:
                            onStateChanged(.finished(true))
                        case .failure(let error):
                            onStateChanged(.error(error))
                        }
                    }
                }))

            case .failure:
                // TODO: Log and inform error
                break
            }
        }
    }

    /// Updates the internal `formType` to `edit` if  the given product exists remotely and previous formType was `.add`
    ///
    func updatedFormTypeIfNeeded(newProduct: Product) {
        guard formType == .add, newProduct.existsRemotely else {
            return
        }
        formType = .edit
    }

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
                                          onCompletion: @escaping (Result<Void, GenerationError>) -> Void) {
        let action = ProductVariationAction.createProductVariations(siteID: product.siteID,
                                                                    productID: product.productID,
                                                                    productVariations: variations, onCompletion: { result in
            switch result {
            case .success:
                onCompletion(.success(()))
            case .failure:
                // TODO: Log Error
                break
            }
        })
        stores.dispatch(action)
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

// MARK: Definitions for Generate All Variations
extension ProductVariationsViewModel {
    /// Type that represents the possible states while all variations are being created.
    ///
    enum GenerationState {
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
        ///
        case finished(_ variationsCreated: Bool)

        /// Error state in any part of the process.
        ///
        case error(GenerationError)
    }

    /// Type to represent known generation errors
    ///
    enum GenerationError: LocalizedError, Equatable {
        case tooManyVariations(variationCount: Int)

        var errorTitle: String {
            switch self {
            case .tooManyVariations:
                return NSLocalizedString("Generation limit exceeded", comment: "Error title for for when there are too many variations to generate.")
            }
        }

        var errorDescription: String? {
            switch self {
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
