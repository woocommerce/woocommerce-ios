import Foundation
import protocol Yosemite.POSOrderableItem
import enum Yosemite.POSItem

struct Cart {
    var items: [CartItem] = []
    var coupons: [CartCouponItem] = []
}

struct CartItem {
    let id: UUID
    let item: POSOrderableItem
    let title: String
    let subtitle: String?
    let quantity: Int
}

struct CartCouponItem {
    let id: UUID
    let code: String
    let summary: String

    init(id: UUID, code: String, summary: String) {
        self.id = id
        self.code = code
        self.summary = summary
    }
}

// MARK: - Helper Methods

extension Cart {
    mutating func add(_ posItem: POSItem) {
        switch posItem {
        case .simpleProduct(let simpleProduct):
            let productItem = CartItem(id: UUID(), item: simpleProduct, title: simpleProduct.name, subtitle: nil, quantity: 1)
            items.insert(productItem, at: items.startIndex)
        case .variation(let variation):
            let productItem = CartItem(id: UUID(), item: variation, title: variation.parentProductName, subtitle: variation.name, quantity: 1)
            items.insert(productItem, at: items.startIndex)
        case .variableParentProduct:
            return
        case .coupon(let coupon):
            let couponItem = CartCouponItem(id: UUID(), code: coupon.code, summary: coupon.summary)
            coupons.insert(couponItem, at: coupons.startIndex)
        }
    }

    mutating func remove(_ cartItem: CartItem) {
        items.removeAll { $0.id == cartItem.id }
    }

    mutating func remove(_ cartCouponItem: CartCouponItem) {
        coupons.removeAll { $0.id == cartCouponItem.id }
    }

    mutating func removeAll() {
        items.removeAll()
        coupons.removeAll()
    }

    var isEmpty: Bool {
        items.isEmpty && coupons.isEmpty
    }

    var isNotEmpty: Bool {
        return !isEmpty
    }
}
