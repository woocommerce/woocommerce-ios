import Foundation

extension Order {
    var status: OrderStatus {
        get {
            switch statusString {
            case "pending":
                return .pending
            case "processing":
                return .processing
            case "on-hold":
                return .onHold
            case "completed":
                return .completed
            case "cancelled":
                return .canceled
            case "refunded":
                return .refunded
            case "failed":
                return .failed
            default:
                NSLog("Error: unidentified order status: %@", statusString)
                return .unknown
            }
        }
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
        case notes = "customer_note"
    }

    var dateCreated: Date {
        get {
            // TODO: use WordPressShared date helpers to convert dateCreatedString into a Date
            return Date()
        }
    }
}
