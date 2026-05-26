import Foundation
import CoreData

extension BookingOrderInfo {
    @NSManaged public var datePaid: Date?
    @NSManaged public var paymentStatusMetadata: String?
    @NSManaged public var refundTotal: NSDecimalNumber?
    @NSManaged public var statusKey: String?
    @NSManaged public var total: NSDecimalNumber?
    @NSManaged public var paymentInfo: BookingPaymentInfo?
    @NSManaged public var customerInfo: BookingCustomerInfo?
    @NSManaged public var productInfo: BookingProductInfo?
    @NSManaged public var booking: Booking?
}
