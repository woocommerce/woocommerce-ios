import Foundation
import protocol Yosemite.POSOrderableItem
import enum Yosemite.POSItem

struct Cart {
    var items: [CartProductItem] = []
    var coupons: [CartCouponItem] = []
}

protocol CartItem: Identifiable {
    var id: UUID { get }
}

struct CartProductItem: CartItem {
    let id: UUID
    let item: POSOrderableItem
    let title: String
    let subtitle: String?
    let quantity: Int
}

struct CartCouponItem: CartItem {
    let id: UUID
    let code: String
}

// MARK: - Helper Methods

extension Cart {
    mutating func add(_ posItem: POSItem) {
        switch posItem {
        case .simpleProduct(let simpleProduct):
            let productItem = CartProductItem(id: UUID(), item: simpleProduct, title: simpleProduct.name, subtitle: nil, quantity: 1)
            items.insert(productItem, at: items.startIndex)
        case .variation(let variation):
            let productItem = CartProductItem(id: UUID(), item: variation, title: variation.parentProductName, subtitle: variation.name, quantity: 1)
            items.insert(productItem, at: items.startIndex)
        case .variableParentProduct:
            return
        case .coupon(let coupon):
            let couponItem = CartCouponItem(id: UUID(), code: coupon.code)
            coupons.insert(couponItem, at: coupons.startIndex)
        }
    }

    mutating func remove(_ cartItem: any CartItem) {
        switch cartItem {
        case _ as CartProductItem:
            items.removeAll { $0.id == cartItem.id }
        case _ as CartCouponItem:
            coupons.removeAll { $0.id == cartItem.id }
        default:
            break
        }
    }

    mutating func removeAll() {
        items.removeAll()
        coupons.removeAll()
    }

    var isEmpty: Bool {
        items.isEmpty && coupons.isEmpty
    }
}
