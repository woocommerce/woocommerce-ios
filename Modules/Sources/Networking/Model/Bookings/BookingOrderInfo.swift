// periphery:ignore:all
import Foundation

public struct BookingOrderInfo: Hashable {
    public let statusKey: String
    public let paymentInfo: BookingPaymentInfo?
    public let customerInfo: BookingCustomerInfo?
    public let productInfo: BookingProductInfo?

    public init(statusKey: String,
                paymentInfo: BookingPaymentInfo?,
                customerInfo: BookingCustomerInfo?,
                productInfo: BookingProductInfo?) {
        self.statusKey = statusKey
        self.paymentInfo = paymentInfo
        self.customerInfo = customerInfo
        self.productInfo = productInfo
    }
}
