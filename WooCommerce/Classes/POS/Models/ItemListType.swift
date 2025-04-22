import enum Yosemite.POSItemType

enum ItemListType: Equatable {
    case products(search: Bool = false)
    case coupons

    var itemType: POSItemType {
        switch self {
        case .coupons:
            return .coupon
        case .products(search: let search):
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
}
