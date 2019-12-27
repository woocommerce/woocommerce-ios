import Foundation
import Storage

// Storage.ShipmentTrackingProvider: ReadOnlyConvertible Conformance.
//

extension Storage.ShipmentTrackingProvider: ReadOnlyConvertible {
    /// Updates the Storage.SiteTrackingProvider with the a ReadOnly.
    ///
    public func update(with shipmentTrackingProvider: Yosemite.ShipmentTrackingProvider) {
        siteID = Int64(shipmentTrackingProvider.siteID)
        name = shipmentTrackingProvider.name
        url = shipmentTrackingProvider.url
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ShipmentTrackingProvider {
        return ShipmentTrackingProvider(siteID: Int64(siteID), name: name ?? "", url: url ?? "")
    }
}
