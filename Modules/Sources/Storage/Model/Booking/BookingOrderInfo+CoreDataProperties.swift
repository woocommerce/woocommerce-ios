import Foundation
import CoreData

extension BookingOrderInfo {
    @NSManaged public var dateCreated: Date?
    @NSManaged public var datePaid: Date?
    @NSManaged public var discountTotal: String?
    @NSManaged public var orderID: Int64
    @NSManaged public var orderNumber: String?
    @NSManaged public var statusKey: String?
    @NSManaged public var paymentInfo: BookingPaymentInfo?
    @NSManaged public var customerInfo: BookingCustomerInfo?
    @NSManaged public var productInfo: BookingProductInfo?
    @NSManaged public var booking: Booking?

}
