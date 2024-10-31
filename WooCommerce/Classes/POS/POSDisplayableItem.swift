import SwiftUI
import struct Yosemite.POSProduct
import protocol Yosemite.POSItem

protocol POSDisplayableItem: Identifiable, Equatable {
    var id: Int64 { get }
    var item: POSItem { get }
    associatedtype ItemView: View
    @ViewBuilder var view: ItemView { get }
}

struct POSProductItem: POSDisplayableItem {
    var id: Int64 {
        product.productID
    }
    var product: POSProduct
    var item: POSItem { product }
    let addItemToCart: (CartItem) -> Void

    init?(item: POSItem, addItemToCart: @escaping(CartItem) -> Void) {
        guard let product = item as? POSProduct else {
            return nil
        }
        self.product = product
        self.addItemToCart = addItemToCart
    }

    @ViewBuilder
    var view: some View {
        Button(action: {
            let cartItem = CartItem(id: UUID(), item: product, quantity: 1)
            addItemToCart(cartItem)
        }, label: {
            ItemCardView(item: product)
        })
    }

    static func ==(lhs: POSProductItem, rhs: POSProductItem) -> Bool {
        return lhs.product == rhs.product
    }
}
