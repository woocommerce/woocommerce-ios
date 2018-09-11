import Foundation


/// Represents an Order Entity.
///
public struct Order: Decodable {
    public let siteID: Int
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
    public let paymentMethodTitle: String

    public let items: [OrderItem]
    public let billingAddress: Address?
    public let shippingAddress: Address?
    public let coupons: [OrderCouponLine]

    /// Order struct initializer.
    ///
    public init(siteID: Int,
                orderID: Int,
                parentID: Int,
                customerID: Int,
                number: String,
                status: OrderStatus,
                currency: String,
                customerNote: String?,
                dateCreated: Date,
                dateModified: Date,
                datePaid: Date?,
                discountTotal: String,
                discountTax: String,
                shippingTotal: String,
                shippingTax: String,
                total: String,
                totalTax: String,
                paymentMethodTitle: String,
                items: [OrderItem],
                billingAddress: Address?,
                shippingAddress: Address?,
                coupons: [OrderCouponLine]) {

        self.siteID = siteID
        self.orderID = orderID
        self.parentID = parentID
        self.customerID = customerID

        self.number = number
        self.status = status
        self.currency = currency
        self.customerNote = customerNote

        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.datePaid = datePaid

        self.discountTotal = discountTotal
        self.discountTax = discountTax
        self.shippingTotal = shippingTotal
        self.shippingTax = shippingTax
        self.total = total
        self.totalTax = totalTax
        self.paymentMethodTitle = paymentMethodTitle

        self.items = items
        self.billingAddress = billingAddress
        self.shippingAddress = shippingAddress
        self.coupons = coupons
    }


    /// The public initializer for Order.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int else {
            throw OrderDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let orderID = try container.decode(Int.self, forKey: .orderID)
        let parentID = try container.decode(Int.self, forKey: .parentID)
        let customerID = try container.decode(Int.self, forKey: .customerID)

        let number = try container.decode(String.self, forKey: .number)
        let status = try container.decode(OrderStatus.self, forKey: .status)
        let currency = try container.decode(String.self, forKey: .currency)
        let customerNote = try container.decode(String.self, forKey: .customerNote)

        let dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated) ?? Date()
        let dateModified = try container.decodeIfPresent(Date.self, forKey: .dateModified) ?? Date()
        let datePaid = try container.decodeIfPresent(Date.self, forKey: .datePaid)

        let discountTotal = try container.decode(String.self, forKey: .discountTotal)
        let discountTax = try container.decode(String.self, forKey: .discountTax)
        let shippingTax = try container.decode(String.self, forKey: .shippingTax)
        let shippingTotal = try container.decode(String.self, forKey: .shippingTotal)
        let total = try container.decode(String.self, forKey: .total)
        let totalTax = try container.decode(String.self, forKey: .totalTax)
        let paymentMethodTitle = try container.decode(String.self, forKey: .paymentMethodTitle)

        let items = try container.decode([OrderItem].self, forKey: .items)

        let shippingAddress = try? container.decode(Address.self, forKey: .shippingAddress)
        let billingAddress = try? container.decode(Address.self, forKey: .billingAddress)

        let coupons = try container.decode([OrderCouponLine].self, forKey: .couponLines)

        self.init(siteID: siteID, orderID: orderID, parentID: parentID, customerID: customerID, number: number, status: status, currency: currency, customerNote: customerNote, dateCreated: dateCreated, dateModified: dateModified, datePaid: datePaid, discountTotal: discountTotal, discountTax: discountTax, shippingTotal: shippingTotal, shippingTax: shippingTax, total: total, totalTax: totalTax, paymentMethodTitle: paymentMethodTitle, items: items, billingAddress: billingAddress, shippingAddress: shippingAddress, coupons: coupons)
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

        case dateCreated        = "date_created_gmt"
        case dateModified       = "date_modified_gmt"
        case datePaid           = "date_paid_gmt"

        case discountTotal      = "discount_total"
        case discountTax        = "discount_tax"
        case shippingTotal      = "shipping_total"
        case shippingTax        = "shipping_tax"
        case total              = "total"
        case totalTax           = "total_tax"
        case paymentMethodTitle = "payment_method_title"

        case items              = "line_items"
        case shippingAddress    = "shipping"
        case billingAddress     = "billing"
        case couponLines        = "coupon_lines"
    }
}


// MARK: - Comparable Conformance
//
extension Order: Comparable {
    public static func == (lhs: Order, rhs: Order) -> Bool {
        return lhs.siteID == rhs.siteID &&
            lhs.orderID == rhs.orderID &&
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
            lhs.paymentMethodTitle == rhs.paymentMethodTitle &&
            lhs.billingAddress == rhs.billingAddress &&
            lhs.shippingAddress == rhs.shippingAddress &&
            lhs.coupons.count == rhs.coupons.count &&
            lhs.coupons.sorted() == rhs.coupons.sorted() &&
            lhs.items.count == rhs.items.count &&
            lhs.items.sorted() == rhs.items.sorted()
    }

    public static func < (lhs: Order, rhs: Order) -> Bool {
        return lhs.orderID < rhs.orderID ||
            (lhs.orderID == rhs.orderID && lhs.dateCreated < rhs.dateCreated) ||
            (lhs.orderID == rhs.orderID && lhs.dateCreated == rhs.dateCreated && lhs.dateModified < rhs.dateModified)
    }
}


// MARK: - Decoding Errors
//
enum OrderDecodingError: Error {
    case missingSiteID
}
