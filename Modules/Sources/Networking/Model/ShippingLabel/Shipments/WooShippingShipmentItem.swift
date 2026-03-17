import Foundation
import Codegen

/// Represents a shipment from the WooCommerce Shipping extension.
///
public struct WooShippingShipment: Equatable, GeneratedFakeable, GeneratedCopiable {
    /// ID of the site that the shipment belongs to.
    public let siteID: Int64

    /// ID of the order that the shipment belongs to.
    public let orderID: Int64

    /// Index of the shipment.
    /// The expected format is a numeric string, e.g: "0", "1", etc.
    public let index: String

    /// Contents of the shipment
    public let items: [WooShippingShipmentItem]

    /// The latest label purchased for the shipment
    public let shippingLabel: ShippingLabel?

    public init(siteID: Int64,
                orderID: Int64,
                index: String,
                items: [WooShippingShipmentItem],
                shippingLabel: ShippingLabel?) {
        self.siteID = siteID
        self.orderID = orderID
        self.index = index
        self.items = items
        self.shippingLabel = shippingLabel
    }
}

/// Represents a shipment item from the WooCommerce Shipping extension.
///
public struct WooShippingShipmentItem: Codable, Equatable, GeneratedFakeable, GeneratedCopiable {
    /// ID of the order item
    public let id: Int64

    /// Items of the shipment
    public let subItems: [String]?

    public init(id: Int64, subItems: [String]?) {
        self.id = id
        self.subItems = subItems
    }
}

public typealias WooShippingShipments = [String: [WooShippingShipmentItem]]

public extension WooShippingShipmentItem {
    var quantity: Decimal {
        guard let subItems else { return 0 }
        return !subItems.isEmpty ? Decimal(subItems.count) : 1
    }
}
