import Foundation
import CoreData

extension BookingOrderRefund {
    @NSManaged public var refundID: Int64
    @NSManaged public var reason: String?
    @NSManaged public var total: String?
    @NSManaged public var orderInfo: BookingOrderInfo?
}
