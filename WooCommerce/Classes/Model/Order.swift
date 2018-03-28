import Foundation

// Mockup Entities
// Ref.: http://woocommerce.github.io/woocommerce-rest-api-docs/#orders
// Ref.: https://github.com/wordpress-mobile/WordPress-FluxC-Android/blob/d05fbb9f1b252c6b6704a5b6ff6723ec990b307e/plugins/woocommerce/src/main/kotlin/org/wordpress/android/fluxc/model/WCOrderModel.kt

// MARK: -
//
struct Order {
    let identifier: String
    let number: String
    let status: OrderStatus
    let customer: Customer
    let dateCreated: Date
    let dateUpdated: Date
    let shippingAddress: Address
    let billingAddress: Address
    let items: [OrderItem]
    let currency: String
    let total: Double
    let notes: [OrderNote]?
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

    var description: String {
        return NSLocalizedString(rawValue, comment: "Order status string")
    }
}

extension OrderStatus {
    static var array: [OrderStatus] {
        var a: [OrderStatus] = []
        switch OrderStatus.pending {
            case .pending: a.append(.pending); fallthrough
            case .processing: a.append(.processing); fallthrough
            case .onHold: a.append(.onHold); fallthrough
            case .failed: a.append(.failed); fallthrough
            case .canceled: a.append(.canceled); fallthrough
            case .completed: a.append(.completed); fallthrough
            case .refunded: a.append(.refunded)
        }
        return a
    }
}


// MARK: -
//
struct OrderItem {
    let lineItemId: Int
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
}


// MARK: -
//
struct OrderNote {
    let date: Date
    let contents: String
    let visibleToCustomers: Bool
}


// MARK: -
//
struct Address {
    let firstName: String
    let lastName: String
    let company: String
    let address1: String
    let address2: String
    let city: String
    let state: String
    let postcode: String
    let country: String
}


//
//
struct Customer {
    let identifier: String
    let firstName: String
    let lastName: String
    let email: String?
    let phone: String?
    let billingAddress: Address?
    let shippingAddress: Address?
}
