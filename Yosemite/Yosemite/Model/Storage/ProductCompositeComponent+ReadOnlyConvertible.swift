import Foundation
import Networking
import Storage

// MARK: - Storage.ProductCompositeComponent: ReadOnlyConvertible
//
extension Storage.ProductCompositeComponent: ReadOnlyConvertible {

    /// Updates the Storage.ProductCompositeComponent with the ReadOnly.
    ///
    public func update(with compositeComponent: Yosemite.ProductCompositeComponent) {
        componentID = compositeComponent.componentID
        title = compositeComponent.title
        imageURL = compositeComponent.imageURL
        optionType = compositeComponent.optionType.rawValue
        optionIDs = compositeComponent.optionIDs
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ProductCompositeComponent {
        return ProductCompositeComponent(componentID: componentID ?? "",
                                         title: title ?? "",
                                         description: "", // TODO-8955: Convert description
                                         imageURL: imageURL ?? "",
                                         optionType: CompositeComponentOptionType(rawValue: optionType ?? "product_ids") ?? .productIDs,
                                         optionIDs: optionIDs ?? [],
                                         defaultOptionID: "") // TODO-8955: Convert default option ID
    }
}
