import Foundation
import Storage


// Storage.OrderFulfillment: ReadOnlyConvertible Conformance.
//
extension Storage.OrderFulfillment: ReadOnlyConvertible {

    /// Updates the Storage.OrderFulfillment with the ReadOnly.
    ///
    public func update(with orderFulfillment: Yosemite.OrderFulfillment) {
        siteID = orderFulfillment.siteID
        orderID = orderFulfillment.orderID
        fulfillmentID = orderFulfillment.fulfillmentID
        statusKey = orderFulfillment.status
        isFulfilled = orderFulfillment.isFulfilled
        dateUpdated = orderFulfillment.dateUpdated
        dateFulfilled = orderFulfillment.dateFulfilled
        trackingNumber = orderFulfillment.trackingNumber
        shipmentProvider = orderFulfillment.shipmentProvider
        trackingURL = orderFulfillment.trackingURL
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.OrderFulfillment {
        return OrderFulfillment(siteID: siteID,
                                orderID: orderID,
                                fulfillmentID: fulfillmentID,
                                status: statusKey,
                                isFulfilled: isFulfilled,
                                dateUpdated: dateUpdated,
                                dateFulfilled: dateFulfilled,
                                trackingNumber: trackingNumber,
                                shipmentProvider: shipmentProvider,
                                trackingURL: trackingURL)
    }
}
