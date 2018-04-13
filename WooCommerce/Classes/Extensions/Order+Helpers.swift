import Foundation

extension Order: Decodable {
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
        case billingAddress = "billing"
        case shippingAddress = "shipping"
        case items = "line_items"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: OrderStructKeys.self)
        let identifier: Int = try container.decode(Int.self, forKey: .identifier)
        let number: String = try container.decode(String.self, forKey: .number)
        let statusString: String = try container.decode(String.self, forKey: .statusString)
        let currency: String = try container.decode(String.self, forKey: .currency)
        let dateCreatedString: String = try container.decode(String.self, forKey: .dateCreatedString)
        let discountTotal: String = try container.decode(String.self, forKey: .discountTotal)
        let couponLines: Array<CouponLine> = try container.decode([CouponLine].self, forKey: .couponLines)
        let shippingTotal: String = try container.decode(String.self, forKey: .shippingTotal)
        let totalTax: String = try container.decode(String.self, forKey: .totalTax)
        let total: String = try container.decode(String.self, forKey: .total)
        let paymentMethod: String = try container.decode(String.self, forKey: .paymentMethod)
        let paymentMethodTitle: String = try container.decode(String.self, forKey: .paymentMethodTitle)
        let customerID: Int = try container.decode(Int.self, forKey: .customerID)
        let customerNote: String = try container.decode(String.self, forKey: .customerNote)
        let billingAddress: Address = try container.decode(Address.self, forKey: .billingAddress)
        let shippingAddress: Address = try container.decode(Address.self, forKey: .shippingAddress)
        let items: Array<OrderItem> = try container.decode([OrderItem].self, forKey: .items)

        self.init(identifier: identifier, number: number, statusString: statusString, currency: currency, dateCreatedString: dateCreatedString, discountTotal: discountTotal, couponLines: couponLines, shippingTotal: shippingTotal, totalTax: totalTax, total: total, paymentMethod: paymentMethod, paymentMethodTitle: paymentMethodTitle, customerID: customerID, customerNote: customerNote, billingAddress: billingAddress, shippingAddress: shippingAddress, items: items)
    }

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
                NSLog("Custom order status: %@", statusString)
                return .custom
            }
        }
    }

    var currencySymbol: String {
        let locale = NSLocale(localeIdentifier: self.currency)
        return locale.displayName(forKey: .currencySymbol, value: self.currency) ?? String()
    }

    var dateCreated: Date {
        get {
            // TODO: use WordPressShared date helpers to convert dateCreatedString into a Date
            return Date()
        }
    }
}
