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

    /// True when the screen was opened from the variations screen, where only the attributes used for variations are listed.
    /// The variations screen is the only one that allows variation creation.
    ///
    var isVariationsFlow: Bool {
        allowVariationCreation
    }

    /// Attributes listed on the screen
    ///
    private var listedAttributes: [ProductAttribute] {
        isVariationsFlow ? product.attributesForVariations : product.attributes
    }

    /// Datasource for the product attributes table view
    ///
    var attributes: [ImageAndTitleAndTextTableViewCell.ViewModel] = []

    /// Defines done button visibility
    ///
    var showDoneButton: Bool {
        allowVariationCreation
    }

    init(product: Product,
         allowVariationCreation: Bool,
         stores: StoresManager = ServiceLocator.stores) {
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
        return listedAttributes[index]
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
        listedAttributes.map { attribute in
            let text = [attribute.options.joined(separator: ", "), labels(for: attribute)]
                .filter { $0.isNotEmpty }
                .joined(separator: "\n")
            return ImageAndTitleAndTextTableViewCell.ViewModel(title: attribute.name,
                                                               text: text,
                                                               numberOfLinesForTitle: 0,
                                                               numberOfLinesForText: 0)
        }
    }

    /// "Used for variations" and "Hidden" labels of an attribute, shown outside the variations flow.
    /// Only variable products use attributes for variations.
    ///
    func labels(for attribute: ProductAttribute) -> String {
        guard !isVariationsFlow else {
            return ""
        }
        let labels = [
            product.productType.isVariable && attribute.variation ? Localization.usedForVariations : nil,
            attribute.visible ? nil : Localization.hidden
        ]
        return labels.compactMap { $0 }.joined(separator: " · ")
    }
}

private extension EditAttributesViewModel {
    enum Localization {
        static let usedForVariations = NSLocalizedString("editAttributesViewModel.usedForVariations",
                                                         value: "Used for variations",
                                                         comment: "Label of a product attribute that is used for variations")
        static let hidden = NSLocalizedString("editAttributesViewModel.hidden",
                                              value: "Hidden",
                                              comment: "Label of a product attribute that is not visible on the product page")
    }
}
