import Foundation
import Storage

// Storage.WooShippingSavedPredefinedPackage: ReadOnlyConvertible Conformance.
//
extension Storage.WooShippingSavedPredefinedPackage: ReadOnlyConvertible {
    /// Updates the Storage.WooShippingSavedPredefinedPackage with the a ReadOnly WooShippingSavedPredefinedPackage.
    ///
    public func update(with savedPackage: Yosemite.WooShippingSavedPredefinedPackage) {
        self.groupTitle = savedPackage.groupTitle
        self.providerID = savedPackage.providerID
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.WooShippingSavedPredefinedPackage {
        .init(groupTitle: groupTitle ?? "",
              providerID: providerID ?? "",
              package: createReadOnlyPackage())
    }

    // MARK: Private helpers

    private func createReadOnlyPackage() -> Yosemite.WooShippingPredefinedPackage {
        guard let package else {
            return WooShippingPredefinedPackage(id: "", name: "", isLetter: false, dimensions: "", boxWeight: "", groupId: "")
        }

        return package.toReadOnly()
    }
}
