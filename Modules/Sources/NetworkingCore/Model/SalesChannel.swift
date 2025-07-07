import Foundation

public enum SalesChannel {
    case pointOfSale
}

extension SalesChannel: RawRepresentable {
    public init?(rawValue: String) {
        switch rawValue {
        case "pos-rest-api":
            self = .pointOfSale
        default:
            return nil
        }
    }

    public var rawValue: String {
        switch self {
        case .pointOfSale:
            return description
        }
    }

    public var description: String {
        switch self {
        case .pointOfSale:
            return NSLocalizedString("salesChannel.pos.description",
                                     value: "POS",
                                     comment: "The acronym for 'Point of Sale'.")
        }
    }
}
