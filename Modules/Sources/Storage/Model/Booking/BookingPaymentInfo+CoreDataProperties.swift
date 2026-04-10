import Foundation
import CoreData

extension BookingPaymentInfo {
    @NSManaged public var paymentMethodID: String?
    @NSManaged public var paymentMethodTitle: String?
    @NSManaged public var subtotal: String?
    @NSManaged public var subtotalTax: String?
    @NSManaged public var total: String?
    @NSManaged public var totalTax: String?
    @NSManaged public var orderInfo: BookingOrderInfo?
}
