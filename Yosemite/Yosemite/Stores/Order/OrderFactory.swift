import Foundation
import Networking

/// Factory to create convenience order types.
///
public enum OrderFactory {
    /// Creates an order suitable to be used as a simple payments order.
    /// Under the hood it uses a fee line with or without taxes to create an order with the desired amount.
    ///
    static func simplePaymentsOrder(status: OrderStatusEnum, amount: String, taxable: Bool) -> Order {
        Order(siteID: 0,
              orderID: 0,
              parentID: 0,
              customerID: 0,
              orderKey: "",
              isEditable: false,
              needsPayment: false,
              needsProcessing: false,
              number: "",
              status: status,
              currency: "",
              customerNote: "",
              dateCreated: Date(),
              dateModified: Date(),
              datePaid: Date(),
              discountTotal: "",
              discountTax: "",
              shippingTotal: "",
              shippingTax: "",
              total: "",
              totalTax: "",
              paymentMethodID: "",
              paymentMethodTitle: "",
              paymentURL: nil,
              chargeID: nil,
              items: [],
              billingAddress: nil,
              shippingAddress: nil,
              shippingLines: [],
              coupons: [],
              refunds: [],
              fees: [simplePaymentFee(feeID: 0, amount: amount, taxable: taxable)],
              taxes: [],
              customFields: [],
              renewalSubscriptionID: nil)
    }

    /// Creates a fee line suitable to be used within a simple payments order.
    ///
    static func simplePaymentFee(feeID: Int64, amount: String, taxable: Bool) -> OrderFeeLine {
        .init(feeID: feeID,
              name: "Simple Payments",
              taxClass: "",
              taxStatus: taxable ? .taxable : .none,
              total: amount,
              totalTax: "",
              taxes: [],
              attributes: [])
    }

    /// Creates a fee line suitable to be used within a new order.
    ///
    public static func newOrderFee(total: String) -> OrderFeeLine {
        OrderFeeLine(feeID: 0,
                     name: "Fee",
                     taxClass: "",
                     taxStatus: .taxable,
                     total: total,
                     totalTax: "",
                     taxes: [],
                     attributes: [])
    }

    /// Creates a coupon line suitable to be used within a new order.
    ///
    public static func newOrderCouponLine(code: String) -> OrderCouponLine {
        .init(couponID: 0,
              code: code,
              discount: "",
              discountTax: "")
    }

    /// Creates a fee line suitable to delete a fee line already saved remotely in an order.
    ///
    public static func deletedFeeLine(_ feeLine: OrderFeeLine) -> OrderFeeLine {
        feeLine.copy(name: .some(nil), total: "0")
    }

    /// Creates a shipping line suitable to delete a shipping line already saved remotely in an order.
    ///
    public static func deletedShippingLine(_ shippingLine: ShippingLine) -> ShippingLine {
        shippingLine.copy(methodID: .some(nil), total: "0")
    }

    /// References a new empty order with constants `Date` values.
    ///
    public static let emptyNewOrder = Order.empty
}
