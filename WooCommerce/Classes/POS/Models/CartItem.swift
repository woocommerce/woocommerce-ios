import Foundation
import protocol Yosemite.POSOrderableItem

struct CartItem {
    let id: UUID
    let item: POSOrderableItem
    let title: String
    let subtitle: String?
    let quantity: Int
}
