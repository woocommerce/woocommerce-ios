import Foundation

// Mockup Entities
// Ref.: http://woocommerce.github.io/woocommerce-rest-api-docs/#orders
// Ref.: https://github.com/wordpress-mobile/WordPress-FluxC-Android/blob/d05fbb9f1b252c6b6704a5b6ff6723ec990b307e/plugins/woocommerce/src/main/kotlin/org/wordpress/android/fluxc/model/WCOrderModel.kt

// MARK: -
//
struct Order: Decodable {
//    let localSiteID: Int // Maps the Order model to the site ID in the database table
    let identifier: Int // The unique ID for this order on the server
    let number: String  // The order number to display to the user
    let statusString: String // String is used in the variable's name to denote that it has a computed property counterpart
    let status: OrderStatus
    let currency: String
    let dateCreatedString: String

    let discountTotal: String
    let couponLines: [CouponLine]
    let shippingTotal: String // The total shipping cost (excluding tax)
    let totalTax: String // The total amount of tax (from products, shipping, discounts, etc.)
    let total: String // Complete total, including taxes

    let paymentMethod: String // Payment method code, e.g. 'cod', 'stripe'
    let paymentMethodTitle: String // Displayable payment method, e.g. 'Cash on delivery', 'Credit Card (Stripe)'

    let customerID: Int
    let customerNote: String?

    let billingAddress: Address
    let shippingAddress: Address

    let items: [OrderItem]

    init(identifier: Int, number: String, statusString: String, status: OrderStatus, currency: String, dateCreatedString: String, discountTotal: String, couponLines: [CouponLine], shippingTotal: String, totalTax: String, total: String, paymentMethod: String, paymentMethodTitle: String, customerID: Int, customerNote: String?, billingAddress: Address, shippingAddress: Address, items: [OrderItem]) {
        self.identifier = identifier
        self.number = number
        self.statusString = statusString
        self.status = status
        self.currency = currency
        self.dateCreatedString = dateCreatedString

        self.discountTotal = discountTotal
        self.couponLines = couponLines
        self.shippingTotal = shippingTotal
        self.totalTax = totalTax
        self.total = total

        self.paymentMethod = paymentMethod
        self.paymentMethodTitle = paymentMethodTitle

        self.customerID = customerID
        self.customerNote = customerNote

        self.billingAddress = billingAddress
        self.shippingAddress = shippingAddress

        self.items = items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: OrderStructKeys.self)
        let identifier = try container.decode(Int.self, forKey: .identifier)
        let number = try container.decode(String.self, forKey: .number)
        let statusString = try container.decode(String.self, forKey: .statusString)
        let status = OrderStatus(rawValue: statusString)
        let currency = try container.decode(String.self, forKey: .currency)
        let dateCreatedString = try container.decode(String.self, forKey: .dateCreatedString)
        let discountTotal = try container.decode(String.self, forKey: .discountTotal)
        let couponLines = try container.decode([CouponLine].self, forKey: .couponLines)
        let shippingTotal = try container.decode(String.self, forKey: .shippingTotal)
        let totalTax = try container.decode(String.self, forKey: .totalTax)
        let total = try container.decode(String.self, forKey: .total)

        let paymentMethod = try container.decode(String.self, forKey: .paymentMethod)
        let paymentMethodTitle = try container.decode(String.self, forKey: .paymentMethodTitle)

        let billingAddress = try container.decode(Address.self, forKey: .billingAddress)
        let shippingAddress = try container.decode(Address.self, forKey: .shippingAddress)

        let customerID = try container.decode(Int.self, forKey: .customerID)
        let customerNote = try container.decode(String.self, forKey: .customerNote)

        let items = try container.decode([OrderItem].self, forKey: .items)

        self.init(identifier: identifier, number: number, statusString: statusString, status: status, currency: currency, dateCreatedString: dateCreatedString, discountTotal: discountTotal, couponLines: couponLines, shippingTotal: shippingTotal, totalTax: totalTax, total: total, paymentMethod: paymentMethod, paymentMethodTitle: paymentMethodTitle, customerID: customerID, customerNote: customerNote, billingAddress: billingAddress, shippingAddress: shippingAddress, items: items)
    }

    var currencySymbol: String {
        let locale = NSLocale(localeIdentifier: self.currency)
        return locale.displayName(forKey: .currencySymbol, value: self.currency) ?? String()
    }

    enum OrderStructKeys: String, CodingKey {
        case identifier = "id"
        case number = "number"
        case statusString = "status"
        case currency = "currency"
        case dateCreatedString = "date_created"
        case discountTotal = "discount_total"
        case couponLines = "coupon_lines"
        case shippingTotal = "shipping_total"
        case totalTax = "total_tax"
        case total = "total"

        case paymentMethod = "payment_method"
        case paymentMethodTitle = "payment_method_title"

        case customerID = "customer_id"
        case customerNote = "customer_note"

        case shippingAddress = "shipping"
        case billingAddress = "billing"

        case items = "line_items"
    }

    var dateCreated: Date {
        // TODO: use WordPressShared date helpers to convert dateCreatedString into a Date
        return Date()
    }
}

// MARK: -
//
enum OrderStatus {
    case pending
    case processing
    case onHold
    case failed
    case canceled
    case completed
    case refunded
    case custom(String)

    var description: String {
        switch self {
        case .pending:
            return NSLocalizedString("Pending", comment: "display order status to user")
        case .processing:
            return NSLocalizedString("Processing", comment: "display order status to user")
        case .onHold:
            return NSLocalizedString("On Hold", comment: "display order status to user")
        case .failed:
            return NSLocalizedString("Failed", comment: "display order status to user")
        case .canceled:
            return NSLocalizedString("Canceled", comment: "display order status to user")
        case .completed:
            return NSLocalizedString("Completed", comment: "display order status to user")
        case .refunded:
            return NSLocalizedString("Refunded", comment: "display order status to user")
        case .custom(let payload):
            return NSLocalizedString("\(payload)", comment: "display custom order status to user")
        }
    }

    init(rawValue: String) {
        switch rawValue {
        case Keys.pending:
            self = .pending
        case Keys.processing:
            self = .processing
        case Keys.onHold:
            self = .onHold
        case Keys.failed:
            self = .failed
        case Keys.cancelled:
            self = .canceled
        case Keys.completed:
            self = .completed
        case Keys.refunded:
            self = .refunded
        default:
            self = .custom(rawValue)
        }
    }

    private enum Keys {
        static let pending = "pending"
        static let processing = "processing"
        static let onHold = "on-hold"
        static let failed =  "failed"
        static let cancelled = "cancelled"
        static let completed = "completed"
        static let refunded = "refunded"
    }
}

extension OrderStatus {
    static var allOrderStatuses: [OrderStatus] {
        return [.pending, .processing, .onHold, .failed, .canceled, .completed, .refunded, .custom(NSLocalizedString("Custom", comment: "Title for button that catches all custom labels and displays them on the order list"))]
    }
}

func ==(lhs: OrderStatus, rhs: OrderStatus) -> Bool {
    return lhs.description == rhs.description
}

// MARK: -
//
struct OrderItem: Decodable {
    let lineItemID: Int
    let name: String
    let productID: Int
    let quantity: Int
    let sku: String
    let subtotal: String
    let subtotalTax: String
    let taxClass: String
    let total: String
    let totalTax: String
    let variationID: Int

    init(lineItemID: Int, name: String, productID: Int, quantity: Int, sku: String, subtotal: String, subtotalTax: String, taxClass: String, total: String, totalTax: String, variationID: Int) {
        self.lineItemID = lineItemID
        self.name = name
        self.productID = productID
        self.quantity = quantity
        self.sku = sku
        self.subtotal = subtotal
        self.subtotalTax = subtotalTax
        self.taxClass = taxClass
        self.total = total
        self.totalTax = totalTax
        self.variationID = variationID
    }

    enum OrderItemStructKeys: String, CodingKey {
        case lineItemID = "id"
        case name = "name"
        case productID = "product_id"
        case quantity = "quantity"
        case sku = "sku"
        case subtotal = "subtotal"
        case subtotalTax = "subtotal_tax"
        case taxClass = "tax_class"
        case total = "total"
        case totalTax = "total_tax"
        case variationID = "variation_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: OrderItemStructKeys.self)

        let lineItemID = try container.decode(Int.self, forKey: .lineItemID)
        let name = try container.decode(String.self, forKey: .name)
        let productID = try container.decode(Int.self, forKey: .productID)
        let quantity = try container.decode(Int.self, forKey: .quantity)
        let sku = try container.decode(String.self, forKey: .sku)
        let subtotal = try container.decode(String.self, forKey: .subtotal)
        let subtotalTax = try container.decode(String.self, forKey: .subtotalTax)
        let taxClass = try container.decode(String.self, forKey: .taxClass)
        let total = try container.decode(String.self, forKey: .total)
        let totalTax = try container.decode(String.self, forKey: .totalTax)
        let variationID = try container.decode(Int.self, forKey: .variationID)

        self.init(lineItemID: lineItemID, name: name, productID: productID, quantity: quantity, sku: sku, subtotal: subtotal, subtotalTax: subtotalTax, taxClass: taxClass, total: total, totalTax: totalTax, variationID: variationID)
    }
}

// MARK: -
//
struct OrderNote: Decodable {
    let date: Date?
    let contents: String?
    let visibleToCustomers: Bool?

    init(date: Date?, contents: String?, visibleToCustomers: Bool?) {
        self.date = date
        self.contents = contents
        self.visibleToCustomers = visibleToCustomers
    }
}

// MARK: -
//
struct CouponLine {
    let identifier: Int
    let code: String

    init(identifier: Int, code: String) {
        self.identifier = identifier
        self.code = code
    }
}

extension CouponLine: Decodable {
    enum CouponLineStructKeys: String, CodingKey {
        case identifier = "id"
        case code = "code"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CouponLineStructKeys.self)
        let identifier: Int = try container.decode(Int.self, forKey: .identifier)
        let code: String = try container.decode(String.self, forKey: .code)

        self.init(identifier: identifier, code: code)
    }
}
