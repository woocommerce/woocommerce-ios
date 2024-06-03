import Foundation
import protocol Yosemite.POSItem

public struct CartItem {
    public let id: UUID
    public let item: POSItem
    public let quantity: Int

    public init(id: UUID, item: POSItem, quantity: Int) {
        self.id = id
        self.item = item
        self.quantity = quantity
    }
}
