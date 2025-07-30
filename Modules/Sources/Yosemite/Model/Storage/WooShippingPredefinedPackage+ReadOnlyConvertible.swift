import Foundation
import Storage

// Storage.WooShippingPredefinedPackage: ReadOnlyConvertible Conformance.
//
extension Storage.WooShippingPredefinedPackage: ReadOnlyConvertible {
    /// Updates the Storage.WooShippingPredefinedPackage with the a ReadOnly WooShippingPredefinedPackage.
    ///
    public func update(with predefinedPackage: Yosemite.WooShippingPredefinedPackage) {
        self.id = predefinedPackage.id
        self.name = predefinedPackage.name
        self.isLetter = predefinedPackage.isLetter
        self.dimensions = predefinedPackage.dimensions
        self.boxWeight = predefinedPackage.boxWeight
        self.groupID = predefinedPackage.groupId
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.WooShippingPredefinedPackage {
        .init(id: id ?? "",
              name: name ?? "",
              isLetter: isLetter,
              dimensions: dimensions ?? "",
              boxWeight: boxWeight ?? "",
              groupId: groupID ?? "")
    }
}
