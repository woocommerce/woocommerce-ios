import Foundation
import Networking


// MARK: - ShipmentAction: Defines all of the Actions supported by the ShipmentStore.
//
public enum ShipmentAction: Action {

    /// Synchronizes all the shipment tracking data associated with the provided `siteID` and `orderID`
    ///
    case synchronizeShipmentTrackingData(siteID: Int64, orderID: Int64, onCompletion: (Error?) -> Void)

    /// Synchronizes all the shipment tracking providers associated with the provided `siteID` and `orderID`
    ///
    case synchronizeShipmentTrackingProviders(siteID: Int64, orderID: Int64, onCompletion: (Error?) -> Void)

    /// Adds a shipment tracking with `trackingID` associated with the provided `siteID` and `orderID`
    ///
    case addTracking(siteID: Int64,
        orderID: Int64,
        providerGroupName: String,
        providerName: String,
        dateShipped: String,
        trackingNumber: String,
        onCompletion: (Error?) -> Void)

    /// Adds a custom shipment tracking with `trackingProvider`, `trackingNumber`
    /// and `trackingURL` associated with the provided `siteID` and `orderID`
    ///
    case addCustomTracking(siteID: Int64,
        orderID: Int64,
        trackingProvider: String,
        trackingNumber: String,
        trackingURL: String,
        dateShipped: String,
        onCompletion: (Error?) -> Void)

    /// Removes a shipment tracking with `trackingID` associated with the provided `siteID` and `orderID`
    ///
    case deleteTracking(siteID: Int64, orderID: Int64, trackingID: String, onCompletion: (Error?) -> Void)
}
