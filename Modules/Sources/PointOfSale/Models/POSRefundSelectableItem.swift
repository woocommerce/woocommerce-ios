import Foundation
import struct Yosemite.POSOrderItem
import typealias Yosemite.OrderItemAttribute

struct POSRefundSelectableItem: Identifiable, Equatable {
    let id: Int64
    let name: String
    let imageSrc: String?
    let formattedPrice: String
    let attributes: [OrderItemAttribute]
    var isSelected: Bool

    init(id: Int64,
         name: String,
         imageSrc: String?,
         formattedPrice: String,
         attributes: [OrderItemAttribute],
         isSelected: Bool = true) {
        self.id = id
        self.name = name
        self.imageSrc = imageSrc
        self.formattedPrice = formattedPrice
        self.attributes = attributes
        self.isSelected = isSelected
    }

    init(from orderItem: POSOrderItem, isSelected: Bool) {
        self.id = orderItem.itemID
        self.name = orderItem.name
        self.imageSrc = orderItem.imageSrc
        self.formattedPrice = orderItem.formattedPrice
        self.attributes = orderItem.attributes
        self.isSelected = isSelected
    }
}
