import Foundation
import Codegen

/// Model to update shipments on an order
///
public struct WooShippingUpdateShipment: Equatable, Encodable, GeneratedFakeable, GeneratedCopiable {
    public let shipmentIdsToUpdate: [String]

    public let shipments: [String: [WooShippingShipment]]

    public init(shipmentIdsToUpdate: [String], shipments: [String: [WooShippingShipment]]) {
        self.shipmentIdsToUpdate = shipmentIdsToUpdate
        self.shipments = shipments
    }
}
