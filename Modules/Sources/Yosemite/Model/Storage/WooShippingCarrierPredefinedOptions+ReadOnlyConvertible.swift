import Foundation
import Storage

extension Storage.WooShippingCarrierPredefinedOptions {
    var predefinedOptionsArray: [Storage.WooShippingPredefinedOption] {
        return predefinedOptions?.toArray() ?? []
    }
}

// Storage.WooShippingCarrierPredefinedOptions: ReadOnlyConvertible Conformance.
//
extension Storage.WooShippingCarrierPredefinedOptions: ReadOnlyConvertible {
    /// Updates the Storage.WooShippingCarrierPredefinedOptions with the a ReadOnly WooShippingCarrierPredefinedOptions.
    ///
    public func update(with carrierPredefinedOptions: Yosemite.WooShippingCarrierPredefinedOptions) {
        self.carrierID = carrierPredefinedOptions.carrierID
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.WooShippingCarrierPredefinedOptions {
        .init(carrierID: carrierID ?? "",
              predefinedOptions: predefinedOptionsArray.map { $0.toReadOnly() })
    }
}
