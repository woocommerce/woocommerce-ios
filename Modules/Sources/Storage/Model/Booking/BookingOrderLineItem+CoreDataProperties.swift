import Foundation
import CoreData

extension BookingOrderLineItem {
    @NSManaged public var itemID: Int64
    @NSManaged public var name: String?
    @NSManaged public var productID: Int64
    @NSManaged public var variationID: Int64
    @NSManaged public var quantity: NSDecimalNumber?
    @NSManaged public var price: NSDecimalNumber?
    @NSManaged public var subtotal: String?
    @NSManaged public var total: String?
    @NSManaged public var totalTax: String?
    @NSManaged public var imageSrc: String?
    @NSManaged public var orderInfo: BookingOrderInfo?
}
