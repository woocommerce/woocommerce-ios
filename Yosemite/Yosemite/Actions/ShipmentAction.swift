import Foundation
import Networking


// MARK: - ShipmentAction: Defines all of the Actions supported by the ShipmentStore.
//
public enum ShipmentAction: Action {

    /// Synchronizes all the shipment tracking data associated with the provided `siteID` and `orderID`
    ///
    case synchronizeShipmentTrackingData(siteID: Int, orderID: Int, onCompletion: (Error?) -> Void)

    /// Synchronizes all the shipment tracking providers associated with the provided `siteID` and `orderID`
    ///
    case synchronizeShipmentTrackingProviders(siteID: Int, orderID: Int, onCompletion: (Error?) -> Void)

    /// Removes a shipment tracking with `trackingID` associated with the provided `siteID` and `orderID`
    case deleteTracking(siteID: Int, orderID: Int, trackingID: String, onCompletion: (Error?) -> Void)
}
