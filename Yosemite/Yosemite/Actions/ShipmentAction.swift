import Foundation
import Networking


// MARK: - ShipmentAction: Defines all of the Actions supported by the ShipmentStore.
//
public enum ShipmentAction: Action {

    /// Synchronizes the all of the shipment tracking associated with the provided `siteID` and `orderID`
    ///
    case synchronizeShipmentTrackingData(siteID: Int, orderID: Int, onCompletion: (Error?) -> Void)
}
