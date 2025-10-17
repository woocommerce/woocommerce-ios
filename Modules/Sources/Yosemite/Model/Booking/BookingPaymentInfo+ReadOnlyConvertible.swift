import Foundation
import Storage

// MARK: - Storage.BookingPaymentInfo: ReadOnlyConvertible
//
extension Storage.BookingPaymentInfo: ReadOnlyConvertible {
    public func update(with paymentInfo: Yosemite.BookingPaymentInfo) {
        paymentMethodID = paymentInfo.paymentMethodID
        paymentMethodTitle = paymentInfo.paymentMethodTitle
        subtotal = paymentInfo.subtotal
        subtotalTax = paymentInfo.subtotalTax
        total = paymentInfo.total
        totalTax = paymentInfo.totalTax
    }

    public func toReadOnly() -> Yosemite.BookingPaymentInfo {
        return .init(paymentMethodID: paymentMethodID ?? "",
                     paymentMethodTitle: paymentMethodTitle ?? "",
                     subtotal: subtotal ?? "",
                     subtotalTax: subtotalTax ?? "",
                     total: total ?? "",
                     totalTax: totalTax ?? "")
    }
}
