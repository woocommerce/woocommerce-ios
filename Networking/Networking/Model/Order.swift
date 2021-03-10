import Foundation


/// Represents an Order Entity.
///
public struct Order: Decodable, GeneratedCopiable, GeneratedFakeable {
    public let siteID: Int64
    public let orderID: Int64
    public let parentID: Int64
    public let customerID: Int64

    public let number: String
    /// The Order status.
    ///
    /// Maps to `OrderStatus.slug`.
    ///
    public let status: OrderStatusEnum
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
    public let paymentMethodID: String
    public let paymentMethodTitle: String

    public let items: [OrderItem]
    public let billingAddress: Address?
    public let shippingAddress: Address?
    public let shippingLines: [ShippingLine]
    public let coupons: [OrderCouponLine]
    public let refunds: [OrderRefundCondensed]
    public let fees: [OrderFeeLine]

    /// Order struct initializer.
    ///
    public init(siteID: Int64,
                orderID: Int64,
                parentID: Int64,
                customerID: Int64,
                number: String,
                status: OrderStatusEnum,
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
                paymentMethodID: String,
                paymentMethodTitle: String,
                items: [OrderItem],
                billingAddress: Address?,
                shippingAddress: Address?,
                shippingLines: [ShippingLine],
                coupons: [OrderCouponLine],
                refunds: [OrderRefundCondensed],
                fees: [OrderFeeLine]) {

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
        self.paymentMethodID = paymentMethodID
        self.paymentMethodTitle = paymentMethodTitle

        self.items = items
        self.billingAddress = billingAddress
        self.shippingAddress = shippingAddress
        self.shippingLines = shippingLines
        self.coupons = coupons
        self.refunds = refunds
        self.fees = fees
    }


    /// The public initializer for Order.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw OrderDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let orderID = try container.decode(Int64.self, forKey: .orderID)
        let parentID = try container.decode(Int64.self, forKey: .parentID)
        let customerID = try container.decode(Int64.self, forKey: .customerID)

        let number = try container.decode(String.self, forKey: .number)
        let status = try container.decode(OrderStatusEnum.self, forKey: .status)

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
        let paymentMethodID = try container.decode(String.self, forKey: .paymentMethodID)
        let paymentMethodTitle = try container.decode(String.self, forKey: .paymentMethodTitle)

        let items = try container.decode([OrderItem].self, forKey: .items)

        let shippingAddress = try? container.decode(Address.self, forKey: .shippingAddress)
        let billingAddress = try? container.decode(Address.self, forKey: .billingAddress)
        let shippingLines = try container.decodeIfPresent([ShippingLine].self, forKey: .shippingLines) ?? []

        let coupons = try container.decode([OrderCouponLine].self, forKey: .couponLines)

        // The refunds field will not always exist in the response, so let's default to an empty array.
        var refunds = try container.decodeIfPresent([OrderRefundCondensed].self, forKey: .refunds) ?? []

        // Filter out refunds with ID equal to 0 (deleted).
        refunds = refunds.filter({ $0.refundID != 0 })

        let fees = try container.decode([OrderFeeLine].self, forKey: .feeLines)

        self.init(siteID: siteID,
                  orderID: orderID,
                  parentID: parentID,
                  customerID: customerID,
                  number: number,
                  status: status,
                  currency: currency,
                  customerNote: customerNote,
                  dateCreated: dateCreated,
                  dateModified: dateModified,
                  datePaid: datePaid,
                  discountTotal: discountTotal,
                  discountTax: discountTax,
                  shippingTotal: shippingTotal,
                  shippingTax: shippingTax,
                  total: total,
                  totalTax: totalTax,
                  paymentMethodID: paymentMethodID,
                  paymentMethodTitle: paymentMethodTitle,
                  items: items,
                  billingAddress: billingAddress,
                  shippingAddress: shippingAddress,
                  shippingLines: shippingLines,
                  coupons: coupons,
                  refunds: refunds,
                  fees: fees)
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
        case paymentMethodID    = "payment_method"
        case paymentMethodTitle = "payment_method_title"

        case items              = "line_items"
        case shippingAddress    = "shipping"
        case billingAddress     = "billing"
        case shippingLines      = "shipping_lines"
        case couponLines        = "coupon_lines"
        case refunds            = "refunds"
        case feeLines           = "fee_lines"
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
            lhs.paymentMethodID == rhs.paymentMethodID &&
            lhs.paymentMethodTitle == rhs.paymentMethodTitle &&
            lhs.billingAddress == rhs.billingAddress &&
            lhs.shippingAddress == rhs.shippingAddress &&
            lhs.shippingLines.count == rhs.shippingLines.count &&
            lhs.shippingLines.sorted() == rhs.shippingLines.sorted() &&
            lhs.coupons.count == rhs.coupons.count &&
            lhs.coupons.sorted() == rhs.coupons.sorted() &&
            lhs.refunds.count == rhs.refunds.count &&
            lhs.refunds.sorted() == rhs.refunds.sorted() &&
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
