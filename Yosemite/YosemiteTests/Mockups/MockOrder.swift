import Foundation
import Networking

final class MockOrder {
    /// Returns an `Order` with empty values. Use `copy()` to modify them.
    func empty() -> Order {
        Order(
            siteID: 0,
            orderID: 0,
            parentID: 0,
            customerID: 0,
            number: "",
            status: .pending,
            currency: "",
            customerNote: nil,
            dateCreated: Date(),
            dateModified: Date(),
            datePaid: nil,
            discountTotal: "",
            discountTax: "",
            shippingTotal: "",
            shippingTax: "",
            total: "",
            totalTax: "",
            paymentMethodTitle: "",
            items: [],
            billingAddress: nil,
            shippingAddress: nil,
            shippingLines: [],
            coupons: [],
            refunds: []
        )
    }
}
