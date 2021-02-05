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

    var attributes: [ProductAttribute] {
        variationModel.allAttributes
    }

    var isChanged: Bool {
        variationModel.productVariation.attributes.sorted { $0.id < $1.id } != editableAttributes.sorted { $0.id < $1.id }
    }

    var resultAttributes: [ProductVariationAttribute] {
        editableAttributes
    }

    func selectedOption(for attribute: ProductAttribute) -> ProductVariationAttribute? {
        return editableAttributes.first(where: { $0.id == attribute.attributeID && $0.name == attribute.name })
    }

    // MARK: Delegate

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
