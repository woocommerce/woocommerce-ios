import Foundation

// Mockup Entities
// Ref.: http://woocommerce.github.io/woocommerce-rest-api-docs/#orders
// Ref.: https://github.com/wordpress-mobile/WordPress-FluxC-Android/blob/d05fbb9f1b252c6b6704a5b6ff6723ec990b307e/plugins/woocommerce/src/main/kotlin/org/wordpress/android/fluxc/model/WCOrderModel.kt

// MARK: -
//
struct Order: Decodable {
    let identifier: Int
    let number: String
    let statusString: String
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

    init(identifier: Int, number: String, statusString: String, customer: Customer?, dateCreatedString: String, dateUpdatedString: String, shippingAddress: Address, billingAddress: Address, items: [OrderItem], currency: String, totalString: String, notes: [OrderNote]?, customerID: Int, customerNote: String?) {
        self.identifier = identifier
        self.number = number
        self.statusString = statusString
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
        let identifier: Int = try container.decode(Int.self, forKey: .identifier)
        let number: String = try container.decode(String.self, forKey: .number)
        let statusString: String = try container.decode(String.self, forKey: .statusString)
        let customer: Customer? = try container.decodeIfPresent(Customer.self, forKey: .customer)
        let dateCreatedString: String = try container.decode(String.self, forKey: .dateCreatedString)
        let dateUpdatedString: String = try container.decode(String.self, forKey: .dateUpdatedString)
        let shippingAddress: Address = try container.decode(Address.self, forKey: .shippingAddress)
        let billingAddress: Address = try container.decode(Address.self, forKey: .billingAddress)
        let items: Array<OrderItem> = try container.decode([OrderItem].self, forKey: .orderItems)
        let currency: String = try container.decode(String.self, forKey: .currency)
        let totalString: String = try container.decode(String.self, forKey: .total)
        let notes: Array<OrderNote>? = try container.decodeIfPresent([OrderNote].self, forKey: .notes)
        let customerID: Int = try container.decode(Int.self, forKey: .customerID)
        let customerNote: String = try container.decode(String.self, forKey: .customerNote)

        self.init(identifier: identifier, number: number, statusString: statusString, customer: customer, dateCreatedString: dateCreatedString, dateUpdatedString: dateUpdatedString, shippingAddress: shippingAddress, billingAddress: billingAddress, items: items, currency: currency, totalString: totalString, notes: notes, customerID: customerID, customerNote: customerNote)
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
        let lineItemID: Int = try container.decode(Int.self, forKey: .lineItemID)
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
