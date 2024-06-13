import Foundation
import protocol Yosemite.POSItem

struct CartItem {
    let id: UUID
    let item: POSItem
    let quantity: Int

    init(id: UUID, item: POSItem, quantity: Int) {
        self.id = id
        self.item = item
        self.quantity = quantity
    }
}
