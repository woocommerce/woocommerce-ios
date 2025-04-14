import Foundation
import protocol Yosemite.POSOrderableItem
import enum Yosemite.POSItem

struct Cart {
    var purchasableItems: [CartItem.PurchasableItem] = []
    var coupons: [CartItem.CouponItem] = []
}

enum CartItem: Identifiable {
    case purchasableItem(PurchasableItem)
    case coupon(CouponItem)

    var id: UUID {
        switch self {
        case .purchasableItem(let item):
            return item.id
        case .coupon(let coupon):
            return coupon.id
        }
    }

    struct PurchasableItem {
        let id: UUID
        let item: POSOrderableItem
        let title: String
        let subtitle: String?
        let quantity: Int
    }

    struct CouponItem {
        let id: UUID
        let code: String
        let summary: String
    }
}

// MARK: - Helper Methods

extension Cart {
    mutating func add(_ posItem: POSItem) {
        switch posItem {
        case .simpleProduct(let simpleProduct):
            let productItem = CartItem.PurchasableItem(id: UUID(), item: simpleProduct, title: simpleProduct.name, subtitle: nil, quantity: 1)
            purchasableItems.insert(productItem, at: purchasableItems.startIndex)
        case .variation(let variation):
            let productItem = CartItem.PurchasableItem(id: UUID(), item: variation, title: variation.parentProductName, subtitle: variation.name, quantity: 1)
            purchasableItems.insert(productItem, at: purchasableItems.startIndex)
        case .variableParentProduct:
            return
        case .coupon(let coupon):
            let couponItem = CartItem.CouponItem(id: UUID(), code: coupon.code, summary: coupon.summary)
            coupons.insert(couponItem, at: coupons.startIndex)
        }
    }

    mutating func remove(_ cartItem: CartItem) {
        switch cartItem {
        case .purchasableItem(let item):
            purchasableItems.removeAll { $0.id == item.id }
        case .coupon(let coupon):
            coupons.removeAll { $0.id == coupon.id }
        }
    }

    mutating func removeAll() {
        purchasableItems.removeAll()
        coupons.removeAll()
    }

    var isEmpty: Bool {
        purchasableItems.isEmpty && coupons.isEmpty
    }

    var isNotEmpty: Bool {
        return !isEmpty
    }
}
