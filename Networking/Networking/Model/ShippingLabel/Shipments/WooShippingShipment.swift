import Foundation
import Codegen
import WooFoundation

/// Represents a shipment in Shipping Labels for the WooCommerce Shipping extension.
///
public struct WooShippingShipment: Codable, Equatable, GeneratedFakeable, GeneratedCopiable {
    /// ID of the shipment
    public let id: Int64

    /// Items of the shipment
    public let subItems: [String]?

    public init(id: Int64, subItems: [String]?) {
        self.id = id
        self.subItems = subItems
    }
}
