import Foundation

public enum SalesChannel {
    case pointOfSale
    case webCheckout
    case wpAdmin
}

extension SalesChannel: RawRepresentable {
    public init?(rawValue: String) {
        switch rawValue {
        case "pos-rest-api":
            self = .pointOfSale
        case "checkout", "store-api":
            self = .webCheckout
        case "admin":
            self = .wpAdmin
        default:
            return nil
        }
    }

    public var rawValue: String {
        switch self {
        case .pointOfSale:
            return description
        case .webCheckout:
            return description
        case .wpAdmin:
            return description
        }
    }

    public var description: String {
        switch self {
        case .pointOfSale:
            return NSLocalizedString("salesChannel.pos.description",
                                     value: "POS",
                                     comment: "The acronym for 'Point of Sale'.")
        case .webCheckout:
            return NSLocalizedString("salesChannel.webCheckout.description",
                                     value: "Web Checkout",
                                     comment: "Orders created through web checkout.")
        case .wpAdmin:
            return NSLocalizedString("salesChannel.wpAdmin.description",
                                     value: "WP-Admin",
                                     comment: "Orders created through WordPress admin interface.")
        }
    }
}
