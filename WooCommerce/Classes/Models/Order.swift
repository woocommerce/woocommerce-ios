import Foundation

// Mockup Entities
// Ref.: http://woocommerce.github.io/woocommerce-rest-api-docs/#orders
// Ref.: https://github.com/wordpress-mobile/WordPress-FluxC-Android/blob/d05fbb9f1b252c6b6704a5b6ff6723ec990b307e/plugins/woocommerce/src/main/kotlin/org/wordpress/android/fluxc/model/WCOrderModel.kt

// MARK: -
//
struct Order {
//    let localSiteID: Int // Maps the Order model to the site ID in the database table
    let identifier: Int // The unique ID for this order on the server
    let number: String  // The order number to display to the user
    let statusString: String // String is used in the variable's name to denote that it has a computed property counterpart
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

    init(identifier: Int, number: String, statusString: String, currency: String, dateCreatedString: String, discountTotal: String, couponLines: [CouponLine], shippingTotal: String, totalTax: String, total: String, paymentMethod: String, paymentMethodTitle: String, customerID: Int, customerNote: String?, billingAddress: Address, shippingAddress: Address, items: [OrderItem]) {
        self.identifier = identifier
        self.number = number
        self.statusString = statusString
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
        self.shippingAddress = shippingAddress
        self.billingAddress = billingAddress
        self.items = items
    }
}

// MARK: -
//
enum OrderStatus: String {
    case pending = "Pending"
    case processing = "Processing"
    case onHold = "On Hold"
    case failed = "Failed"
    case canceled = "Canceled"
    case completed = "Completed"
    case refunded = "Refunded"
    case custom = "Custom"

    var description: String {
        return NSLocalizedString(rawValue, comment: "Order status string")
    }
}

extension OrderStatus {
    static var allOrderStatuses: [OrderStatus] {
        return [.pending, .processing, .onHold, .failed, .canceled, .completed, .refunded, .custom]
    }
}


// MARK: -
//
struct OrderItem {
    let identifier: Int // The lineItemID
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

    init(identifier: Int, name: String, productID: Int, quantity: Int, sku: String, subtotal: String, subtotalTax: String, taxClass: String, total: String, totalTax: String, variationID: Int) {
        self.identifier = identifier
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
        case identifier = "id"
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
        let identifier: Int = try container.decode(Int.self, forKey: .identifier)
        let name: String = try container.decode(String.self, forKey: .name)
        let productID: Int = try container.decode(Int.self, forKey: .productID)
        let quantity: Int = try container.decode(Int.self, forKey: .quantity)
        let sku: String = try container.decode(String.self, forKey: .sku)
        let subtotal: String = try container.decode(String.self, forKey: .subtotal)
        let subtotalTax: String = try container.decode(String.self, forKey: .subtotalTax)
        let taxClass: String = try container.decode(String.self, forKey: .taxClass)
        let total: String = try container.decode(String.self, forKey: .total)
        let totalTax: String = try container.decode(String.self, forKey: .totalTax)
        let variationID: Int = try container.decode(Int.self, forKey: .variationID)

        self.init(identifier: identifier, name: name, productID: productID, quantity: quantity, sku: sku, subtotal: subtotal, subtotalTax: subtotalTax, taxClass: taxClass, total: total, totalTax: totalTax, variationID: variationID)
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
    let email: String?
    let phone: String?

    init(firstName: String, lastName: String, company: String?, address1: String, address2: String?, city: String, state: String, postcode: String, country: String, email: String?, phone: String?) {
        self.firstName = firstName
        self.lastName = lastName
        self.company = company
        self.address1 = address1
        self.address2 = address2
        self.city = city
        self.state = state
        self.postcode = postcode
        self.country = country
        self.email = email
        self.phone = phone
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
        case email = "email"
        case phone = "phone"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AddressStructKeys.self)
        let firstName: String = try container.decode(String.self, forKey: .firstName)
        let lastName: String = try container.decode(String.self, forKey: .lastName)
        let company: String? = try container.decodeIfPresent(String.self, forKey: .company)
        let address1: String = try container.decode(String.self, forKey: .address1)
        let address2: String? = try container.decodeIfPresent(String.self, forKey: .address2)
        let city: String = try container.decode(String.self, forKey: .city)
        let state: String = try container.decode(String.self, forKey: .state)
        let postcode: String = try container.decode(String.self, forKey: .postcode)
        let country: String = try container.decode(String.self, forKey: .country)
        let email: String? = try container.decodeIfPresent(String.self, forKey: .email)
        let phone: String? = try container.decodeIfPresent(String.self, forKey: .phone)

        self.init(firstName: firstName, lastName: lastName, company: company, address1: address1, address2: address2, city: city, state: state, postcode: postcode, country: country, email: email, phone: phone)
    }
}

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
