import enum Yosemite.POSItemType

enum ItemListType: Equatable, Hashable {
    case products(search: Bool = false)
    case coupons(search: Bool = false)

    var itemType: POSItemType {
        switch self {
        case .coupons:
            return .coupon
        case .products:
            return .product
        }
    }

    var isProducts: Bool {
        switch self {
        case .products:
            return true
        case .coupons:
            return false
        }
    }

    var isCoupons: Bool {
        switch self {
        case .products:
            return false
        case .coupons:
            return true
        }
    }

    var isSearching: Bool {
        switch self {
        case let .products(search), let .coupons(search):
            return search
        }
    }
}
