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
                                         imageURL: imageURL ?? "",
                                         optionType: CompositeComponentOptionType(rawValue: optionType ?? "product_ids") ?? .productIDs,
                                         optionIDs: optionIDs ?? [])
    }
}
