import Foundation
import Storage

extension Storage.WooShippingPackagesResponse {
    var allPredefinedOptionsArray: [Storage.WooShippingCarrierPredefinedOptions] {
        return allPredefinedOptions?.toArray() ?? []
    }
}

// Storage.WooShippingPackagesResponse: ReadOnlyConvertible Conformance.
//
extension Storage.WooShippingPackagesResponse: ReadOnlyConvertible {
    /// Updates the Storage.WooShippingPackagesResponse with the a ReadOnly WooShippingPackagesResponse.
    ///
    public func update(with packages: Yosemite.WooShippingPackagesResponse) {
        self.siteID = packages.siteID
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.WooShippingPackagesResponse {
        .init(siteID: siteID,
              customPackages: customPackages?.map { $0.toReadOnly() } ?? [],
              savedPredefinedPackages: savedPredefinedPackages?.map { $0.toReadOnly() } ?? [],
              allPredefinedOptions: allPredefinedOptionsArray.map { $0.toReadOnly() })
    }
}
