import Foundation
import protocol Yosemite.POSOrderableItem
import enum Yosemite.POSItem
import enum Yosemite.PointOfSaleBarcodeScanError

public struct Cart {
    public var purchasableItems: [Cart.PurchasableItem] = []
    public var coupons: [Cart.CouponItem] = []

    public var accessibilityFocusedItemID: UUID? = nil

    public init(purchasableItems: [Cart.PurchasableItem] = [],
                coupons: [Cart.CouponItem] = [],
                accessibilityFocusedItemID: UUID? = nil) {
        self.purchasableItems = purchasableItems
        self.coupons = coupons
        self.accessibilityFocusedItemID = accessibilityFocusedItemID
    }
}

public protocol CartItem {
    var id: UUID { get }
    var type: CartItemType { get }
}

public enum CartItemType: CaseIterable {
    case purchasableItem
    case coupon
}

public extension Cart {
    struct PurchasableItem: CartItem {
        public let id: UUID
        public let title: String
        public let subtitle: String?
        public let quantity: Int
        public let type: CartItemType = .purchasableItem
        public let state: ItemState
        public let accessibilityLabel: String?

        public enum ItemState {
            case loaded(POSOrderableItem)
            case loading
            case error

            public var isLoading: Bool {
                switch self {
                case .loading:
                    return true
                default:
                    return false
                }
            }
        }

        public var formattedPrice: String? {
            switch state {
            case .loaded(let item):
                return item.formattedPrice
            case .loading, .error:
                return nil
            }
        }

        public init(id: UUID, title: String, subtitle: String?, quantity: Int, state: ItemState, accessibilityLabel: String? = nil) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.quantity = quantity
            self.state = state
            self.accessibilityLabel = accessibilityLabel
        }

        public init(id: UUID, item: POSOrderableItem, title: String, subtitle: String?, quantity: Int) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.quantity = quantity
            self.state = .loaded(item)
            self.accessibilityLabel = nil
        }

        public static func loading(id: UUID) -> PurchasableItem {
            PurchasableItem(
                id: id,
                title: "Loading...",
                subtitle: nil,
                quantity: 1,
                state: .loading
            )
        }
    }

    struct CouponItem: CartItem {
        public let id: UUID
        public let code: String
        public let summary: String
        public let type: CartItemType = .coupon

        public init(id: UUID, code: String, summary: String) {
            self.id = id
            self.code = code
            self.summary = summary
        }
    }
}

// MARK: - Helper Methods

public extension Cart {
    mutating func add(_ posItem: POSItem) {
        if let purchasableItem = createPurchasableItem(id: UUID(), from: posItem) {
            purchasableItems.insert(purchasableItem, at: purchasableItems.startIndex)
        } else if case .coupon(let coupon) = posItem {
            let couponItem = Cart.CouponItem(id: coupon.id, code: coupon.code, summary: coupon.summary)
            coupons.insert(couponItem, at: coupons.startIndex)
        }
    }

    private func createPurchasableItem(id: UUID, from posItem: POSItem) -> Cart.PurchasableItem? {
        switch posItem {
        case .simpleProduct(let simpleProduct):
            return PurchasableItem(id: UUID(), item: simpleProduct, title: simpleProduct.name, subtitle: nil, quantity: 1)
        case .variation(let variation):
            return PurchasableItem(id: UUID(), item: variation, title: variation.parentProductName, subtitle: variation.name, quantity: 1)
        case .variableParentProduct, .coupon:
            return nil
        }
    }

    mutating func addLoadingItem() -> Cart.PurchasableItem {
        let id = UUID()
        let loadingItem = PurchasableItem.loading(id: id)
        purchasableItems.insert(loadingItem, at: purchasableItems.startIndex)
        return loadingItem
    }

    @discardableResult
    mutating func updateLoadingItem(id: UUID, with posItem: POSItem) -> Cart.PurchasableItem? {
        guard let index = purchasableItems.firstIndex(where: { $0.id == id }) else { return nil }

        if let productItem = createPurchasableItem(id: id, from: posItem) {
            purchasableItems[index] = productItem
            return productItem
        } else {
            purchasableItems.remove(at: index)
            return nil
        }
    }

    mutating func removeItem(id: UUID) {
        purchasableItems.removeAll(where: { $0.id == id })
    }

    var isEmpty: Bool {
        purchasableItems.isEmpty && coupons.isEmpty
    }

    var isNotEmpty: Bool {
        return !isEmpty
    }
}
