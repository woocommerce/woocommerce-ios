import Foundation
import typealias Yosemite.POSOrderableItem

struct CartItem {
    let id: UUID
    let item: any POSOrderableItem
    let quantity: Int

    init(id: UUID, item: any POSOrderableItem, quantity: Int) {
        self.id = id
        self.item = item
        self.quantity = quantity
    }
}
