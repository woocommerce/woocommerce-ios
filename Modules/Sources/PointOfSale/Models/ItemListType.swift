import enum Yosemite.POSItemType

public enum ItemListType: Equatable, Hashable {
    case products(search: Bool = false)
    case coupons(search: Bool = false)

    public var itemType: POSItemType {
        switch self {
        case .coupons:
            return .coupon
        case .products:
            return .product
        }
    }

    public var isProducts: Bool {
        switch self {
        case .products:
            return true
        case .coupons:
            return false
        }
    }

    public var isCoupons: Bool {
        switch self {
        case .products:
            return false
        case .coupons:
            return true
        }
    }

    public var isSearching: Bool {
        switch self {
        case let .products(search), let .coupons(search):
            return search
        }
    }
}
