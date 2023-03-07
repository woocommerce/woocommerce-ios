import Foundation
import Yosemite

final class EditAttributesViewModel {

    /// Main product dependency
    ///
    private(set) var product: Product {
        didSet {
            self.attributes = createAttributeViewModels()
        }
    }

    /// If true, a done button will appear that allows the merchant to generate a variation
    ///
    private let allowVariationCreation: Bool

    /// Stores dependency. Needed to generate variations
    ///
    private let stores: StoresManager

    /// Datasource for the product attributes table view
    ///
    var attributes: [ImageAndTitleAndTextTableViewCell.ViewModel] = []

    /// Defines done button visibility
    ///
    var showDoneButton: Bool {
        allowVariationCreation
    }

    init(product: Product, allowVariationCreation: Bool, stores: StoresManager = ServiceLocator.stores) {
        self.product = product
        self.allowVariationCreation = allowVariationCreation
        self.stores = stores
        self.attributes = createAttributeViewModels()
    }
}

// MARK: View Controller inputs
extension EditAttributesViewModel {

    /// Updates the view model output properties based on the provided `product`.
    ///
    func updateProduct(_ product: Product) {
        self.product = product
    }

    /// Generates a variation in the host site using the product attributes
    ///
    func generateVariation(onCompletion: @escaping (Result<(Product, ProductVariation), Error>) -> Void) {
        let useCase = GenerateVariationUseCase(product: product, stores: stores)
        useCase.generateVariation(onCompletion: onCompletion)
    }

    /// Returns the underlying `ProductAttribute` that fuels an `attributes` type  at the given index.
    ///
    func productAttributeAtIndex(_ index: Int) -> ProductAttribute {
        return product.attributesForVariations[index]
    }

    /// Generates all missing variations for a product. Up to 100 variations.
    /// Parameters:
    /// - `onStateChanged`: Closure invoked every time there is a significant state change in the generation process.
    ///
    func generateAllVariations(onStateChanged: @escaping (GenerateAllVariationsUseCase.State) -> Void) {
        let useCase = GenerateAllVariationsUseCase(stores: stores)
        useCase.generateAllVariations(for: product, onStateChanged: onStateChanged)
    }
}

// MARK: Helpers
private extension EditAttributesViewModel {

    /// Creates an array of `ImageAndTitleAndTextTableViewCell.ViewModel` based on the `product.attributes`
    func createAttributeViewModels() -> [ImageAndTitleAndTextTableViewCell.ViewModel] {
        product.attributesForVariations.map { attribute in
            ImageAndTitleAndTextTableViewCell.ViewModel(title: attribute.name,
                                                        text: attribute.options.joined(separator: ", "),
                                                        numberOfLinesForTitle: 0,
                                                        numberOfLinesForText: 0)
        }
    }
}
