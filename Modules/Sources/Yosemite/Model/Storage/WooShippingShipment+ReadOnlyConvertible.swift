import Foundation
import Storage

// Storage.WooShippingShipment: ReadOnlyConvertible Conformance.
//
extension Storage.WooShippingShipment: ReadOnlyConvertible {
    /// Updates the Storage.WooShippingShipment with the a ReadOnly WooShippingShipment.
    ///
    public func update(with savedShipment: Yosemite.WooShippingShipment) {
        self.siteID = savedShipment.siteID
        self.orderID = savedShipment.orderID
        self.index = savedShipment.index
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.WooShippingShipment {
        let shipmentShippingLabel = shippingLabel?.toReadOnly()
        let shipmentItems = items?.map { $0.toReadOnly() } ?? [Yosemite.WooShippingShipmentItem]()

        return WooShippingShipment(siteID: siteID,
                                   orderID: orderID,
                                   index: index,
                                   items: shipmentItems,
                                   shippingLabel: shipmentShippingLabel)
    }
}
