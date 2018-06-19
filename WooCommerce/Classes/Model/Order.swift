import Foundation
import UIKit

// Mockup Entities
// Ref.: http://woocommerce.github.io/woocommerce-rest-api-docs/#orders
// Ref.: https://github.com/wordpress-mobile/WordPress-FluxC-Android/blob/d05fbb9f1b252c6b6704a5b6ff6723ec990b307e/plugins/woocommerce/src/main/kotlin/org/wordpress/android/fluxc/model/WCOrderModel.kt

// MARK: -
//
struct Order: Decodable {
    let identifier: Int
    let number: String
    let statusString: String
    let status: OrderStatus
    var customer: Customer?
    let dateCreatedString: String
    let dateUpdatedString: String
    let shippingAddress: Address
    let billingAddress: Address
    let items: [OrderItem]
    let currency: String
    let total: String
    var notes: [OrderNote]?
    let customerID: Int
    let customerNote: String?
    let couponLines: [CouponLine]?
    let discountTotal: String
    let shippingTotal: String
    let totalTax: String
    let paymentMethod: String
    let paymentMethodTitle: String

    init(identifier: Int, number: String, statusString: String, status: OrderStatus, customer: Customer?, dateCreatedString: String, dateUpdatedString: String, shippingAddress: Address, billingAddress: Address, items: [OrderItem], currency: String, total: String, notes: [OrderNote]?, customerID: Int, customerNote: String?, couponLines: [CouponLine]?, discountTotal: String, shippingTotal: String, totalTax: String, paymentMethod: String, paymentMethodTitle: String) {
        self.identifier = identifier
        self.number = number
        self.statusString = statusString
        self.status = status
        self.customer = customer
        self.dateCreatedString = dateCreatedString
        self.dateUpdatedString = dateUpdatedString
        self.shippingAddress = shippingAddress
        self.billingAddress = billingAddress
        self.items = items
        self.currency = currency
        self.total = total
        self.notes = notes
        self.customerID = customerID
        self.customerNote = customerNote
        self.couponLines = couponLines
        self.discountTotal = discountTotal
        self.shippingTotal = shippingTotal
        self.totalTax = totalTax
        self.paymentMethod = paymentMethod
        self.paymentMethodTitle = paymentMethodTitle
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: OrderStructKeys.self)
        let identifier = try container.decode(Int.self, forKey: .identifier)
        let number = try container.decode(String.self, forKey: .number)
        let statusString = try container.decode(String.self, forKey: .statusString)
        let status = OrderStatus(rawValue: statusString)
        let customer = try container.decodeIfPresent(Customer.self, forKey: .customer)
        let dateCreatedString = try container.decode(String.self, forKey: .dateCreatedString)
        let dateUpdatedString = try container.decode(String.self, forKey: .dateUpdatedString)
        let shippingAddress = try container.decode(Address.self, forKey: .shippingAddress)
        let billingAddress = try container.decode(Address.self, forKey: .billingAddress)
        let items = try container.decode([OrderItem].self, forKey: .orderItems)
        let currency = try container.decode(String.self, forKey: .currency)
        let total = try container.decode(String.self, forKey: .total)
        let notes = try container.decodeIfPresent([OrderNote].self, forKey: .notes)
        let customerID = try container.decode(Int.self, forKey: .customerID)
        let customerNote = try container.decode(String.self, forKey: .customerNote)
        let couponLines = try container.decodeIfPresent([CouponLine].self, forKey: .couponLines)
        let discountTotal = try container.decode(String.self, forKey: .discountTotal)
        let shippingTotal = try container.decode(String.self, forKey: .shippingTotal)
        let totalTax = try container.decode(String.self, forKey: .totalTax)
        let paymentMethod = try container.decode(String.self, forKey: .paymentMethod)
        let paymentMethodTitle = try container.decode(String.self, forKey: .paymentMethodTitle)

        self.init(identifier: identifier, number: number, statusString: statusString, status: status, customer: customer, dateCreatedString: dateCreatedString, dateUpdatedString: dateUpdatedString, shippingAddress: shippingAddress, billingAddress: billingAddress, items: items, currency: currency, total: total, notes: notes, customerID: customerID, customerNote: customerNote, couponLines: couponLines, discountTotal: discountTotal, shippingTotal: shippingTotal, totalTax: totalTax, paymentMethod: paymentMethod, paymentMethodTitle: paymentMethodTitle)
    }

    var currencySymbol: String {
        let locale = NSLocale(localeIdentifier: self.currency)
        return locale.displayName(forKey: .currencySymbol, value: self.currency) ?? String()
    }

    enum OrderStructKeys: String, CodingKey {
        case identifier = "id"
        case number = "number"
        case statusString = "status"
        case customer = "customer"
        case customerID = "customer_id"
        case dateCreatedString = "date_created"
        case dateUpdatedString = "date_modified"
        case shippingAddress = "shipping"
        case billingAddress = "billing"
        case orderItems = "line_items"
        case currency = "currency"
        case total = "total"
        case customerNote = "customer_note"
        case notes = "notes"
        case couponLines = "coupon_lines"
        case discountTotal = "discount_total"
        case shippingTotal = "shipping_total"
        case totalTax = "total_tax"
        case paymentMethod = "payment_method"
        case paymentMethodTitle = "payment_method_title"
    }

    var dateCreated: Date {
        // TODO: use WordPressShared date helpers to convert dateCreatedString into a Date
        return Date()
    }

    var subtotal: String {
        let subtotal = items.reduce(0.0) { (output, item) in
            let itemSubtotal = Double(item.subtotal) ?? 0.0
            return output + itemSubtotal
        }

        return String(format: "%.2f", subtotal)
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
    static var allOrderStatusDescriptions: [String] {
        return allOrderStatuses.map { $0.description }
    }
    var backgroundColor: UIColor {
        switch self {
        case .processing:
            fallthrough
        case .pending:
            return StyleManager.statusSuccessColor
        case .failed:
            fallthrough
        case .refunded:
            return StyleManager.statusDangerColor
        case .completed:
            return StyleManager.statusPrimaryColor
        case .onHold:
            fallthrough
        case .canceled:
            fallthrough
        case .custom:
            fallthrough
        default:
            return StyleManager.statusNotIdentifiedColor
        }
    }
    var borderColor: CGColor {
        switch self {
        case .processing:
            fallthrough
        case .pending:
            return StyleManager.statusSuccessBoldColor.cgColor
        case .failed:
            fallthrough
        case .refunded:
            return StyleManager.statusDangerBoldColor.cgColor
        case .completed:
            return StyleManager.statusPrimaryBoldColor.cgColor
        case .onHold:
            fallthrough
        case .canceled:
            fallthrough
        case .custom:
            fallthrough
        default:
            return StyleManager.statusNotIdentifiedBoldColor.cgColor
        }
    }
}

func ==(lhs: OrderStatus, rhs: OrderStatus) -> Bool {
    return lhs.description == rhs.description
}

// MARK: -
//
struct OrderItem {
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
}

extension OrderItem : Decodable {
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
    let identifier: Int
    let dateCreated: String
    let contents: String
    let isCustomerNote: Bool

    init(identifier: Int, dateCreated: String, contents: String, isCustomerNote: Bool) {
        self.identifier = identifier
        self.dateCreated = dateCreated
        self.contents = contents
        self.isCustomerNote = isCustomerNote
    }

    enum OrderNoteStructKeys: String, CodingKey {
        case identifier = "id"
        case dateCreated = "date_created"
        case contents = "note"
        case isCustomerNote = "customer_note"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: OrderNoteStructKeys.self)
        let identifier = try container.decode(Int.self, forKey: .identifier)
        let dateCreated = try container.decode(String.self, forKey: .dateCreated)
        let contents = try container.decode(String.self, forKey: .contents)
        let isCustomerNote = try container.decode(Bool.self, forKey: .isCustomerNote)

        self.init(identifier: identifier, dateCreated: dateCreated, contents: contents, isCustomerNote: isCustomerNote)
    }
}


// MARK: -
//
struct Address {
    let firstName: String
    let lastName: String
    let company: String?
    let address1: String
    let address2: String?
    let city: String
    let state: String
    let postcode: String
    let country: String
    let phone: String?
    let email: String?

    init(firstName: String, lastName: String, company: String?, address1: String, address2: String?, city: String, state: String, postcode: String, country: String, phone: String?, email: String?) {
        self.firstName = firstName
        self.lastName = lastName
        self.company = company
        self.address1 = address1
        self.address2 = address2
        self.city = city
        self.state = state
        self.postcode = postcode
        self.country = country
        self.phone = phone
        self.email = email
    }
}

extension Address: Decodable {
    enum AddressStructKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case company = "company"
        case address1 = "address_1"
        case address2 = "address_2"
        case city = "city"
        case state = "state"
        case postcode = "postcode"
        case country = "country"
        case phone = "phone"
        case email = "email"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AddressStructKeys.self)

        let firstName = try container.decode(String.self, forKey: .firstName)
        let lastName = try container.decode(String.self, forKey: .lastName)
        let company = try container.decodeIfPresent(String.self, forKey: .company)
        let address1 = try container.decode(String.self, forKey: .address1)
        let address2 = try container.decodeIfPresent(String.self, forKey: .address2)
        let city = try container.decode(String.self, forKey: .city)
        let state = try container.decode(String.self, forKey: .state)
        let postcode = try container.decode(String.self, forKey: .postcode)
        let country = try container.decode(String.self, forKey: .country)
        let phone = try container.decodeIfPresent(String.self, forKey: .phone)
        let email = try container.decodeIfPresent(String.self, forKey: .email)

        self.init(firstName: firstName, lastName: lastName, company: company, address1: address1, address2: address2, city: city, state: state, postcode: postcode, country: country, phone: phone, email: email)
    }
}

//
//
struct Customer {
    let identifier: Int
    let firstName: String
    let lastName: String
    let email: String?
    let phone: String?
    let billingAddress: Address?
    let shippingAddress: Address?
    let note: String?

    init(identifier: Int, firstName: String, lastName: String, email: String?, phone: String?, billingAddress: Address?, shippingAddress: Address?, note: String?) {
        self.identifier = identifier
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.billingAddress = billingAddress
        self.shippingAddress = shippingAddress
        self.note = note
    }
}

extension Customer: Decodable {
    enum CustomerStructKeys: String, CodingKey {
        case identifier = "id"
        case firstName = "first_name"
        case lastName = "last_name"
        case email = "billing.email"
        case phone = "billing.phone"
        case billingAddress = "billing"
        case shippingAddress = "shipping"
        case note = "customer_note"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CustomerStructKeys.self)
        let identifier: Int = try container.decode(Int.self, forKey: .identifier)
        let firstName: String = try container.decode(String.self, forKey: .firstName)
        let lastName: String = try container.decode(String.self, forKey: .lastName)
        let billingAddress: Address = try container.decode(Address.self, forKey: .billingAddress)
        let shippingAddress: Address = try container.decode(Address.self, forKey: .shippingAddress)
        let email: String? = try container.decodeIfPresent(String.self, forKey: .email)
        let phone: String? = try container.decodeIfPresent(String.self, forKey: .phone)
        let note: String? = try container.decode(String.self, forKey: .note)

        self.init(identifier: identifier, firstName: firstName, lastName: lastName, email: email, phone: phone, billingAddress: billingAddress, shippingAddress: shippingAddress, note: note)
    }
}

struct CouponLine: Decodable {
    let id: Int
    let code: String

    init(id: Int, code: String) {
        self.id = id
        self.code = code
    }

    enum CouponLineStructKeys: String, CodingKey {
        case id = "id"
        case code = "code"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CouponLineStructKeys.self)
        let id = try container.decode(Int.self, forKey: .id)
        let code = try container.decode(String.self, forKey: .code)

        self.init(id: id, code: code)
    }
}
