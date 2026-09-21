import Foundation
import Storage

// Storage.WooShippingPredefinedOption: ReadOnlyConvertible Conformance.
//
extension Storage.WooShippingPredefinedOption: ReadOnlyConvertible {
    /// Updates the Storage.WooShippingPredefinedOption with the a ReadOnly WooShippingPredefinedOption.
    ///
    public func update(with option: Yosemite.WooShippingPredefinedOption) {
        self.title = option.title
        self.providerID = option.providerID
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.WooShippingPredefinedOption {
        .init(title: title ?? "",
              providerID: providerID ?? "",
              predefinedPackages: predefinedPackages?.map { $0.toReadOnly() } ?? [])
    }
}
