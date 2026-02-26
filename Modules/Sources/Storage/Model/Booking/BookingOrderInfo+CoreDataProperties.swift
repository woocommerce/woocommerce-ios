import Foundation
import CoreData

extension BookingOrderInfo {
    @NSManaged public var statusKey: String?
    @NSManaged public var paymentInfo: BookingPaymentInfo?
    @NSManaged public var customerInfo: BookingCustomerInfo?
    @NSManaged public var productInfo: BookingProductInfo?
    @NSManaged public var booking: Booking?

}
