import Networking

/// How product variations are sorted in a product list.
///
public enum ProductVariationsSortOrder: String {
    // From the newest to the oldest
    case dateDescending
    // From the oldest to the newest
    case dateAscending
    // Product name from Z to A
    case nameDescending
    // Product name from A to Z
    case nameAscending

    public static let `default`: ProductVariationsSortOrder = .nameAscending
}

// MARK: ProductsRemote
//
extension ProductVariationsSortOrder {
    var remoteOrderKey: ProductVariationsRemote.OrderKey {
        switch self {
        case .dateAscending, .dateDescending:
            return .date
        case .nameAscending, .nameDescending:
            return .title
        }
    }

    var remoteOrder: ProductVariationsRemote.Order {
        switch self {
        case .dateAscending, .nameAscending:
            return .ascending
        case .dateDescending, .nameDescending:
            return .descending
        }
    }
}
