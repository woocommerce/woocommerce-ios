import Foundation
import Storage

// Storage.ShipmentTrackingProviderGroup: ReadOnlyConvertible Conformance.
//
extension Storage.ShipmentTrackingProviderGroup: ReadOnlyConvertible {

    /// Updates the Storage.SiteTrackingProviderGroup with the a ReadOnly.
    ///
    public func update(with shipmentTrackingProviderGroup: Yosemite.ShipmentTrackingProviderGroup) {
        name = shipmentTrackingProviderGroup.name
        siteID = shipmentTrackingProviderGroup.siteID
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ShipmentTrackingProviderGroup {
        let groupProviders = providers?.map { $0.toReadOnly() } ?? [Yosemite.ShipmentTrackingProvider]()
        return ShipmentTrackingProviderGroup(name: name ?? "", siteID: siteID, providers: groupProviders )
    }
}
