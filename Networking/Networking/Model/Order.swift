import Foundation


/// Represents an Order Entity.
///
public struct Order: Decodable {
    public let orderID: Int
    public let parentID: Int
    public let customerID: Int

    public let number: String
    public let status: OrderStatus
    public let currency: String
    public let customerNote: String?

    public let dateCreated: Date
    public let dateModified: Date
    public let datePaid: Date?

    public let discountTotal: String
    public let discountTax: String
    public let shippingTotal: String
    public let shippingTax: String
    public let total: String
    public let totalTax: String

    public let items: [OrderItem]
    public let billingAddress: Address
    public let shippingAddress: Address
}


/// Defines all of the Order CodingKeys
///
private extension Order {

    enum CodingKeys: String, CodingKey {
        case orderID            = "id"
        case parentID           = "parent_id"
        case customerID         = "customer_id"

        case number             = "number"
        case status             = "status"
        case currency           = "currency"
        case customerNote       = "customer_note"

        case dateCreated        = "date_created_gmt"
        case dateModified       = "date_modified_gmt"
        case datePaid           = "date_paid_gmt"

        case discountTotal      = "discount_total"
        case discountTax        = "discount_tax"
        case shippingTotal      = "shipping_total"
        case shippingTax        = "shipping_tax"
        case total              = "total"
        case totalTax           = "total_tax"

        case items              = "line_items"
        case shippingAddress    = "shipping"
        case billingAddress     = "billing"
    }
}


// MARK: - Comparable Conformance
//
extension Order: Comparable {
    public static func == (lhs: Order, rhs: Order) -> Bool {
        print(lhs.items.sorted())
        print("&&")
        print(rhs.items.sorted())
        print("---")
        return lhs.orderID == rhs.orderID &&
            lhs.parentID == rhs.parentID &&
            lhs.customerID == rhs.customerID &&
            lhs.number == rhs.number &&
            lhs.status == rhs.status &&
            lhs.dateCreated == rhs.dateCreated &&
            lhs.dateModified == rhs.dateModified &&
            lhs.datePaid == rhs.datePaid &&
            lhs.discountTotal == rhs.discountTotal &&
            lhs.discountTax == rhs.discountTax &&
            lhs.shippingTotal == rhs.shippingTotal &&
            lhs.shippingTax == rhs.shippingTax &&
            lhs.total == rhs.total &&
            lhs.totalTax == rhs.totalTax &&
            lhs.billingAddress == rhs.billingAddress &&
            lhs.shippingAddress == rhs.shippingAddress &&
            lhs.items.count == rhs.items.count &&
            lhs.items.sorted() == rhs.items.sorted()
    }

    public static func < (lhs: Order, rhs: Order) -> Bool {
        return lhs.orderID < rhs.orderID ||
            (lhs.orderID == rhs.orderID && lhs.dateCreated < rhs.dateCreated) ||
            (lhs.orderID == rhs.orderID && lhs.dateCreated == rhs.dateCreated && lhs.dateModified < rhs.dateModified)
    }
}
