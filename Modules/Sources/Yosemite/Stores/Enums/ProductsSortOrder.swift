import Networking

/// How products are sorted in a product list.
///
public enum ProductsSortOrder: String {
    // From the newest to the oldest
    case dateDescending
    // From the oldest to the newest
    case dateAscending
    // Product name from Z to A
    case nameDescending
    // Product name from A to Z
    case nameAscending

    public static let `default`: ProductsSortOrder = .nameAscending
}

// MARK: ProductsRemote
//
extension ProductsSortOrder {
    var remoteOrderKey: ProductsRemote.OrderKey {
        switch self {
        case .dateAscending, .dateDescending:
            return .date
        case .nameAscending, .nameDescending:
            return .name
        }
    }

    var remoteOrder: ProductsRemote.Order {
        switch self {
        case .dateAscending, .nameAscending:
            return .ascending
        case .dateDescending, .nameDescending:
            return .descending
        }
    }
}

// MARK: Analytics properties
public extension ProductsSortOrder {
    var analyticsDescription: String {
        switch self {
        case .dateAscending:
            return "date,ascending"
        case .dateDescending:
            return "date,descending"
        case .nameAscending:
            return "name,ascending"
        case .nameDescending:
            return "name,descending"
        }
    }
}
