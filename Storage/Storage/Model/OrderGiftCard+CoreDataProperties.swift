import Foundation
import CoreData


extension OrderGiftCard {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OrderGiftCard> {
        return NSFetchRequest<OrderGiftCard>(entityName: "OrderGiftCard")
    }

    @NSManaged public var giftCardID: Int64
    @NSManaged public var code: String?
    @NSManaged public var amount: Double
    @NSManaged public var order: Order?

}

extension OrderGiftCard: Identifiable {

}
