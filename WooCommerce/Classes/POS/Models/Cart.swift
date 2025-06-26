import Foundation
import protocol Yosemite.POSOrderableItem
import enum Yosemite.POSItem
import enum Yosemite.PointOfSaleBarcodeScanError

struct Cart {
    var purchasableItems: [Cart.PurchasableItem] = []
    var coupons: [Cart.CouponItem] = []

    var accessibilityFocusedItemID: UUID? = nil
}

protocol CartItem {
    var id: UUID { get }
    var type: CartItemType { get }
}

enum CartItemType: CaseIterable {
    case purchasableItem
    case coupon
}

extension Cart {
    struct PurchasableItem: CartItem {
        let id: UUID
        let title: String
        let subtitle: String?
        let quantity: Int
        let type: CartItemType = .purchasableItem
        let state: ItemState
        let accessibilityLabel: String?

        enum ItemState {
            case loaded(POSOrderableItem)
            case loading
            case error

            var isLoading: Bool {
                switch self {
                case .loading:
                    return true
                default:
                    return false
                }
            }
        }

        var formattedPrice: String? {
            switch state {
            case .loaded(let item):
                return item.formattedPrice
            case .loading, .error:
                return nil
            }
        }

        init(id: UUID, title: String, subtitle: String?, quantity: Int, state: ItemState, accessibilityLabel: String? = nil) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.quantity = quantity
            self.state = state
            self.accessibilityLabel = accessibilityLabel
        }

        init(id: UUID, item: POSOrderableItem, title: String, subtitle: String?, quantity: Int) {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.quantity = quantity
            self.state = .loaded(item)
            self.accessibilityLabel = nil
        }

        static func loading(id: UUID) -> PurchasableItem {
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
        let id: UUID
        let code: String
        let summary: String
        let type: CartItemType = .coupon
    }
}

// MARK: - Helper Methods

extension Cart {
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
