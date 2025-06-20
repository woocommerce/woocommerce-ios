import Foundation
import Storage

// Storage.WooShippingCustomPackage: ReadOnlyConvertible Conformance.
//
extension Storage.WooShippingCustomPackage: ReadOnlyConvertible {
    /// Updates the Storage.WooShippingCustomPackage with the a ReadOnly WooShippingCustomPackage.
    ///
    public func update(with customPackage: Yosemite.WooShippingCustomPackage) {
        self.id = customPackage.id
        self.name = customPackage.name
        self.dimensions = customPackage.dimensions
        self.boxWeight = customPackage.boxWeight
        self.rawType = customPackage.rawType
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.WooShippingCustomPackage {
        .init(id: id ?? "",
              name: name ?? "",
              rawType: rawType ?? "box",
              dimensions: dimensions ?? "",
              boxWeight: boxWeight)
    }
}
