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
    let totalString: String
    let notes: [OrderNote]?
    let customerID: Int
    let customerNote: String?

    init(identifier: Int, number: String, statusString: String, status: OrderStatus, customer: Customer?, dateCreatedString: String, dateUpdatedString: String, shippingAddress: Address, billingAddress: Address, items: [OrderItem], currency: String, totalString: String, notes: [OrderNote]?, customerID: Int, customerNote: String?) {
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
        self.totalString = totalString
        self.notes = notes
        self.customerID = customerID
        self.customerNote = customerNote
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
        let totalString = try container.decode(String.self, forKey: .total)
        let notes = try container.decodeIfPresent([OrderNote].self, forKey: .notes)
        let customerID = try container.decode(Int.self, forKey: .customerID)
        let customerNote = try container.decode(String.self, forKey: .customerNote)

        self.init(identifier: identifier, number: number, statusString: statusString, status: status, customer: customer, dateCreatedString: dateCreatedString, dateUpdatedString: dateUpdatedString, shippingAddress: shippingAddress, billingAddress: billingAddress, items: items, currency: currency, totalString: totalString, notes: notes, customerID: customerID, customerNote: customerNote)
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
        case dateUpdatedString = "date_modified_gmt"
        case shippingAddress = "shipping"
        case billingAddress = "billing"
        case orderItems = "line_items"
        case currency = "currency"
        case total = "total"
        case customerNote = "customer_note"
        case notes = "notes"
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
