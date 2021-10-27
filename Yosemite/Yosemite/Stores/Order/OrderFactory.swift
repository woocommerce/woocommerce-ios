import Foundation
import Networking

/// Factory to create convenience order types.
///
enum OrderFactory {
    /// Creates an order suitable to be used as a quick order order.
    /// Under the hood it uses a fee line without taxes to create an order with the desired amount.
    ///
    static func quickOrderOrder(amount: String) -> Order {
        Order(siteID: 0,
              orderID: 0,
              parentID: 0,
              customerID: 0,
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
              fees: [.init(feeID: 0, name: "Quick Order", taxClass: "", taxStatus: .none, total: amount, totalTax: "", taxes: [], attributes: [])])
    }
}
