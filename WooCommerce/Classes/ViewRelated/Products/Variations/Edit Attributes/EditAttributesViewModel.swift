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
    func generateVariation(onCompletion: @escaping (Result<ProductVariation, Error>) -> Void) {
        let action = ProductVariationAction.createProductVariation(siteID: product.siteID,
                                                                   productID: product.productID,
                                                                   newVariation: createVariationParameter()) { result in
            onCompletion(result)
        }
        stores.dispatch(action)
    }
}

// MARK: Helpers
private extension EditAttributesViewModel {

    /// Creates an array of `ImageAndTitleAndTextTableViewCell.ViewModel` based on the `product.attributes`
    func createAttributeViewModels() -> [ImageAndTitleAndTextTableViewCell.ViewModel] {
        product.attributes.map { attribute in
            ImageAndTitleAndTextTableViewCell.ViewModel(title: attribute.name,
                                                        text: attribute.options.joined(separator: ", "),
                                                        numberOfLinesForTitle: 0,
                                                        numberOfLinesForText: 0)
        }
    }

    /// Returns a `CreateProductVariation` type with no price and no options selected for any of it's attributes.
    ///
    func createVariationParameter() -> CreateProductVariation {
        let attributes = product.attributes.map { ProductVariationAttribute(id: $0.attributeID, name: $0.name, option: "") }
        return CreateProductVariation(regularPrice: "", attributes: attributes)
    }
}
