import Foundation
import Storage


// MARK: - Yosemite.ShipmentTracking: ReadOnlyType
//
extension Yosemite.ShipmentTracking: ReadOnlyType {

    /// Indicates if the receiver is the Storage.Entity, backing up the specified ReadOnly.Entity.
    ///
    public func isReadOnlyRepresentation(of storageEntity: Any) -> Bool {
        guard let storageShipmentTracking = storageEntity as? Storage.ShipmentTracking else {
            return false
        }

        return siteID == Int(storageShipmentTracking.siteID) &&
            orderID == Int(storageShipmentTracking.orderID) &&
            trackingID == storageShipmentTracking.trackingID
    }
}
