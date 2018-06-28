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

    private let dateCreatedString: String?
    private let dateModifiedString: String?

    public let discountTotal: String
    public let discountTax: String
    public let shippingTotal: String
    public let shippingTax: String
    public let total: String
    public let totalTax: String

    public let items: [OrderItem]
    public let billingAddress: Address
    public let shippingAddress: Address

    init(orderID: Int, parentID: Int, customerID: Int, number: String, status: OrderStatus, currency: String, customerNote: String?, dateCreatedString: String?, dateModifiedString: String?, datePaid: Date?, discountTotal: String, discountTax: String, shippingTotal: String, shippingTax: String, total: String, totalTax: String, items: [OrderItem], billingAddress: Address, shippingAddress: Address) {
        self.orderID = orderID
        self.parentID = parentID
        self.customerID = customerID

        self.number = number
        self.status = status
        self.currency = currency
        self.customerNote = customerNote

        self.dateCreatedString = dateCreatedString == nil ? "" : dateCreatedString
        self.dateModifiedString = dateModifiedString
        self.datePaid = datePaid

        let format = ISO8601DateFormatter()
        var dateCreated: Date?
        if let createdString = dateCreatedString {
            dateCreated = format.date(from: createdString)
        }

        if let dateCreated = dateCreated {
            self.dateCreated = dateCreated
        } else {
            self.dateCreated = Date()
        }

        var dateModified: Date?
        if let modifiedString = dateModifiedString {
            dateModified = format.date(from: modifiedString)
        }

        if let dateModified = dateModified {
            self.dateModified = dateModified
        } else {
            self.dateModified = Date()
        }

        self.discountTotal = discountTotal
        self.discountTax = discountTax
        self.shippingTotal = shippingTotal
        self.shippingTax = shippingTax
        self.total = total
        self.totalTax = totalTax

        self.items = items
        self.billingAddress = billingAddress
        self.shippingAddress = shippingAddress
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let orderID = try container.decode(Int.self, forKey: .orderID)
        let parentID = try container.decode(Int.self, forKey: .parentID)
        let customerID = try container.decode(Int.self, forKey: .customerID)

        let number = try container.decode(String.self, forKey: .number)
        let status = try container.decode(OrderStatus.self, forKey: .status)
        let currency = try container.decode(String.self, forKey: .currency)
        let customerNote = try container.decode(String.self, forKey: .customerNote)

        let dateCreatedString = try container.decodeIfPresent(String.self, forKey: .dateCreatedString)
        let dateModifiedString = try container.decodeIfPresent(String.self, forKey: .dateModifiedString)
        let datePaid = try container.decodeIfPresent(Date.self, forKey: .datePaid)

        let discountTotal = try container.decode(String.self, forKey: .discountTotal)
        let discountTax = try container.decode(String.self, forKey: .discountTax)
        let shippingTax = try container.decode(String.self, forKey: .shippingTax)
        let shippingTotal = try container.decode(String.self, forKey: .shippingTotal)
        let total = try container.decode(String.self, forKey: .total)
        let totalTax = try container.decode(String.self, forKey: .totalTax)

        let items = try container.decode([OrderItem].self, forKey: .items)
        let shippingAddress = try container.decode(Address.self, forKey: .shippingAddress)
        let billingAddress = try container.decode(Address.self, forKey: .billingAddress)

        self.init(orderID: orderID, parentID: parentID, customerID: customerID, number: number, status: status, currency: currency, customerNote: customerNote, dateCreatedString: dateCreatedString, dateModifiedString: dateModifiedString, datePaid: datePaid, discountTotal: discountTotal, discountTax: discountTax, shippingTotal: shippingTotal, shippingTax: shippingTax, total: total, totalTax: totalTax, items: items, billingAddress: billingAddress, shippingAddress: shippingAddress)
    }
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

        case dateCreatedString  = "date_created_gmt"
        case dateModifiedString = "date_modified_gmt"
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
