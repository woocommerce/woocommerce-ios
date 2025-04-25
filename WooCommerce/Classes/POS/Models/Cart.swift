import Foundation
import protocol Yosemite.POSOrderableItem
import enum Yosemite.POSItem

struct Cart {
    var purchasableItems: [Cart.PurchasableItem] = []
    var coupons: [Cart.CouponItem] = []
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
        let item: POSOrderableItem
        let title: String
        let subtitle: String?
        let quantity: Int
        let type: CartItemType = .purchasableItem
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
        switch posItem {
        case .simpleProduct(let simpleProduct):
            let productItem = Cart.PurchasableItem(id: UUID(), item: simpleProduct, title: simpleProduct.name, subtitle: nil, quantity: 1)
            purchasableItems.insert(productItem, at: purchasableItems.startIndex)
        case .variation(let variation):
            let productItem = Cart.PurchasableItem(id: UUID(), item: variation, title: variation.parentProductName, subtitle: variation.name, quantity: 1)
            purchasableItems.insert(productItem, at: purchasableItems.startIndex)
        case .variableParentProduct:
            return
        case .coupon(let coupon):
            guard !coupons.contains(where: { $0.id == coupon.id }) else { return }

            let couponItem = Cart.CouponItem(id: coupon.id, code: coupon.code, summary: coupon.summary)
            coupons.insert(couponItem, at: coupons.startIndex)
        }
    }

    var isEmpty: Bool {
        purchasableItems.isEmpty && coupons.isEmpty
    }

    var isNotEmpty: Bool {
        return !isEmpty
    }
}
