import Foundation
import protocol Yosemite.POSOrderableItem

struct CartItem {
    let id: UUID
    let item: POSOrderableItem
    let quantity: Int

    init(id: UUID, item: POSOrderableItem, quantity: Int) {
        self.id = id
        self.item = item
        self.quantity = quantity
    }
}
