import Foundation
import Alamofire


/// ShipmentsRemote: Remote Endpoints
///
public final class ShipmentsRemote: Remote {

    /// Retrieves all of the shipment tracking info for a given order.
    ///
    /// - Parameters:
    ///   - siteID: Site which hosts the Order
    ///   - orderID: Identifier of the Order
    ///   - completion: Closure to be executed upon completion
    ///
    public func loadShipmentTrackings(for siteID: Int, orderID: Int, completion: @escaping ([ShipmentTracking]?, Error?) -> Void) {
        let path = "\(Constants.ordersPath)/" + String(orderID) + "/" + "\(Constants.shipmentPath)/"

        // 2019-2-15 — We are using the v2 endpoint here because this endpoint does not support v3 yet
        let request = JetpackRequest(wooApiVersion: .mark2, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = ShipmentTrackingListMapper(siteID: siteID, orderID: orderID)

        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants!
//
private extension ShipmentsRemote {

    enum Constants {
        static let ordersPath: String   = "orders"
        static let shipmentPath: String = "shipment-trackings"
    }
}
