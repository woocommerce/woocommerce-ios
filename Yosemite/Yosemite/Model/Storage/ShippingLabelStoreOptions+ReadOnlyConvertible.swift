import Foundation
import Storage

// Storage.ShippingLabelStoreOptions: ReadOnlyConvertible Conformance.
//
extension Storage.ShippingLabelStoreOptions: ReadOnlyConvertible {
    /// Updates the Storage.ShippingLabelStoreOptions with the a ReadOnly ShippingLabelStoreOptions.
    ///
    ///
    public func update(with storeOptions: Yosemite.ShippingLabelStoreOptions) {
        currencySymbol = storeOptions.currencySymbol
        dimensionUnit = storeOptions.dimensionUnit
        weightUnit = storeOptions.weightUnit
        originCountry = storeOptions.originCountry
    }

    public func update(with storeOptions: Yosemite.ShippingLabelStoreOptions, siteID: Int64) {
        self.siteID = siteID
        update(with: storeOptions)
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ShippingLabelStoreOptions {
        return ShippingLabelStoreOptions(currencySymbol: currencySymbol ?? "",
                                         dimensionUnit: dimensionUnit ?? "",
                                         weightUnit: weightUnit ?? "",
                                         originCountry: originCountry ?? "")
    }
}
