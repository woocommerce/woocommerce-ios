import Foundation
import Storage


// Storage.ShipmentTracking: ReadOnlyConvertible Conformance.
//
extension Storage.ShipmentTracking: ReadOnlyConvertible {

    /// Updates the Storage.SiteSetting with the a ReadOnly.
    ///
    public func update(with shipmentTracking: Yosemite.ShipmentTracking) {
        siteID = Int64(shipmentTracking.siteID)
        orderID = Int64(shipmentTracking.orderID)
        trackingID = shipmentTracking.trackingID
        trackingNumber = shipmentTracking.trackingNumber
        trackingProvider = shipmentTracking.trackingProvider
        trackingURL = shipmentTracking.trackingURL
        dateShipped = shipmentTracking.dateShipped
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ShipmentTracking {
        return ShipmentTracking(siteID: Int64(siteID),
                                orderID: Int64(orderID),
                                trackingID: trackingID,
                                trackingNumber: trackingNumber ?? "",
                                trackingProvider: trackingProvider,
                                trackingURL: trackingURL,
                                dateShipped: dateShipped)
    }
}
