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
    /// - `onConfirmation`: Closure invoked before creating the variation as a confirmation guard.
    ///                    It provides another `onCompletion` closure to be invoked with the confirmation result.
    /// - `onCompletion`: Closure invoked when the generate process has ended.
    ///
    func generateAllVariations(for product: Product,
                               onConfirmation: @escaping (_ numberOfVariations: Int, _ onCompletion: @escaping (Bool) -> Void) -> Void,
                               onCompletion: @escaping (Result<Void, GenerationError>) -> Void) {

        fetchAllVariations(of: product) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let existingVariations):

                let variationsToGenerate = ProductVariationGenerator.generateVariations(for: product, excluding: existingVariations)

                // Guard for 100 variation limit
                guard variationsToGenerate.count <= 100 else {
                    return onCompletion(.failure(.tooManyVariations(variationCount: variationsToGenerate.count)))
                }

                guard variationsToGenerate.count > 0 else {
                    // TODO: Inform user that no variation will be created
                    return onCompletion(.success(()))
                }

                // Wait for user confirmation before continuing
                onConfirmation(variationsToGenerate.count) { confirmed in
                    if confirmed {
                        self.createVariationsRemotely(for: product, variations: variationsToGenerate, onCompletion: onCompletion)
                    }
                }

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

extension ProductVariationsViewModel {
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
