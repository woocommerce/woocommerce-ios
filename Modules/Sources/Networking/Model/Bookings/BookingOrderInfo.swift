// periphery:ignore:all
import Foundation

public struct BookingOrderInfo: Hashable {
    public let statusKey: String
    public let orderID: Int64
    public let orderNumber: String?
    public let dateCreated: Date?
    public let datePaid: Date?
    public let discountTotal: String?
    public let paymentInfo: BookingPaymentInfo?
    public let customerInfo: BookingCustomerInfo?
    public let productInfo: BookingProductInfo?

    public init(statusKey: String,
                orderID: Int64 = 0,
                orderNumber: String? = nil,
                dateCreated: Date? = nil,
                datePaid: Date? = nil,
                discountTotal: String? = nil,
                paymentInfo: BookingPaymentInfo?,
                customerInfo: BookingCustomerInfo?,
                productInfo: BookingProductInfo?) {
        self.statusKey = statusKey
        self.orderID = orderID
        self.orderNumber = orderNumber
        self.dateCreated = dateCreated
        self.datePaid = datePaid
        self.discountTotal = discountTotal
        self.paymentInfo = paymentInfo
        self.customerInfo = customerInfo
        self.productInfo = productInfo
    }

    public init(booking: Booking, order: Order) {
        self.orderID = order.orderID
        self.orderNumber = order.number
        self.dateCreated = order.dateCreated
        self.datePaid = order.datePaid
        self.discountTotal = order.discountTotal
        self.customerInfo = {
            guard let billingAddress = order.billingAddress else {
                return nil
            }
            return BookingCustomerInfo(
                billingAddress: billingAddress,
                note: order.customerNote
            )
        }()
        self.productInfo = BookingProductInfo(name: order.items.first(where: { $0.productID == booking.productID })?.name ?? "")
        self.paymentInfo = BookingPaymentInfo(
            paymentMethodID: order.paymentMethodID,
            paymentMethodTitle: order.paymentMethodTitle,
            subtotal: order.items.map({ Double($0.subtotal) ?? 0 }).reduce(0, +).description,
            subtotalTax: order.items.map({ Double($0.subtotalTax) ?? 0 }).reduce(0, +).description,
            total: order.total,
            totalTax: order.totalTax
        )
        self.statusKey = order.status.rawValue
    }
}
