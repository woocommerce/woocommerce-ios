import Foundation
import Codegen

/// Model to update shipments on an order
///
public struct WooShippingUpdateShipment: Equatable, Encodable, GeneratedFakeable, GeneratedCopiable {
    public let shipmentIdsToUpdate: [String]

    public let shipments: WooShippingShipments

    public init(shipmentIdsToUpdate: [String], shipments: WooShippingShipments) {
        self.shipmentIdsToUpdate = shipmentIdsToUpdate
        self.shipments = shipments
    }
}
