import Foundation
import Yosemite

final class AttributePickerViewModel {

    private let variationModel: EditableProductVariationModel
    private var editableAttributes: [ProductVariationAttribute]

    init(variationModel: EditableProductVariationModel) {
        self.variationModel = variationModel
        self.editableAttributes = variationModel.productVariation.attributes
    }

    // MARK: DataSource

    /// All attributes for a product variation, including "any"
    var attributes: [ProductAttribute] {
        variationModel.allAttributes
    }

    /// Returns whether there are unsaved changes.
    /// Comparison of arrays uses sorting because order doesn't matter.
    var isChanged: Bool {
        variationModel.productVariation.attributes.sorted { $0.id < $1.id } != editableAttributes.sorted { $0.id < $1.id }
    }

    /// Attributes set (excluding "any") for a product variation after all updates
    var resultAttributes: [ProductVariationAttribute] {
        editableAttributes
    }

    /// Selected option for variation attribute. Will be `nil` if option is "any"
    func selectedOption(for attribute: ProductAttribute) -> ProductVariationAttribute? {
        return editableAttributes.first(where: { $0.id == attribute.attributeID && $0.name == attribute.name })
    }

    // MARK: Delegate

    /// Replace old option for attribute with updated one. For "any" options use `nil`.
    func update(oldAttribute: ProductVariationAttribute?, to newAttribute: ProductVariationAttribute?) {
        switch (oldAttribute, newAttribute) {
        case (nil, let newAttribute?):
            editableAttributes.append(newAttribute)
        case (let oldAttribute?, nil):
            if let index = editableAttributes.firstIndex(of: oldAttribute) {
                editableAttributes.remove(at: index)
            }
        case (let oldAttribute?, let newAttribute?):
            if let index = editableAttributes.firstIndex(of: oldAttribute) {
                editableAttributes.remove(at: index)
                editableAttributes.insert(newAttribute, at: index)
            }
        case (nil, nil):
            break
        }
    }
}
