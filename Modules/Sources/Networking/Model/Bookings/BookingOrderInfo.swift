// periphery:ignore:all
import Foundation

public struct BookingOrderInfo: Hashable {
    public let statusKey: String
    public let datePaid: Date?
    public let total: Decimal
    public let refundTotal: Decimal
    public let paymentInfo: BookingPaymentInfo?
    public let customerInfo: BookingCustomerInfo?
    public let productInfo: BookingProductInfo?

    public init(statusKey: String,
                datePaid: Date?,
                total: Decimal = 0,
                refundTotal: Decimal = 0,
                paymentInfo: BookingPaymentInfo?,
                customerInfo: BookingCustomerInfo?,
                productInfo: BookingProductInfo?) {
        self.statusKey = statusKey
        self.datePaid = datePaid
        self.total = total
        self.refundTotal = refundTotal
        self.paymentInfo = paymentInfo
        self.customerInfo = customerInfo
        self.productInfo = productInfo
    }

    public init(booking: Booking, order: Order) {
        self.datePaid = order.datePaid
        self.total = Decimal(string: order.total) ?? 0
        self.refundTotal = order.refunds
            .compactMap { Decimal(string: $0.total) }
            .map { abs($0) }
            .reduce(0, +)
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
