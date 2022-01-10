import Foundation
import Networking

/// Factory to create convenience order types.
///
enum OrderFactory {
    /// Creates an order suitable to be used as a simple payments order.
    /// Under the hood it uses a fee line with or without taxes to create an order with the desired amount.
    ///
    static func simplePaymentsOrder(amount: String, taxable: Bool) -> Order {
        Order(siteID: 0,
              orderID: 0,
              parentID: 0,
              customerID: 0,
              orderKey: "",
              number: "",
              status: .pending,
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
              items: [],
              billingAddress: nil,
              shippingAddress: nil,
              shippingLines: [],
              coupons: [],
              refunds: [],
              fees: [simplePaymentFee(feeID: 0, amount: amount, taxable: taxable)])
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
}
