import Foundation
import Codegen

/// Model to update shipments on an order
///
public struct WooShippingUpdateShipment: Equatable, Encodable, GeneratedFakeable, GeneratedCopiable {
    public let shipmentIdsToUpdate: [String: Int]

    public let shipments: WooShippingShipments

    public init(shipmentIdsToUpdate: [String: Int], shipments: WooShippingShipments) {
        self.shipmentIdsToUpdate = shipmentIdsToUpdate
        self.shipments = shipments
    }
}
