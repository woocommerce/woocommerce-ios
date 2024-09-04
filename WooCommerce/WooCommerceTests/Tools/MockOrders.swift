import Yosemite
import Foundation

final class MockOrders {
    let siteID: Int64 = 1234
    let orderID: Int64 = 5678

    /// Returns an `Order` with empty values. Use `copy()` to modify them.
    func empty() -> Order {
        Order.fake()
    }

    func makeOrder(status: OrderStatusEnum = .processing,
                   items: [OrderItem] = [],
                   shippingLines: [ShippingLine] = sampleShippingLines(),
                   refunds: [OrderRefundCondensed] = [],
                   fees: [OrderFeeLine] = [],
                   taxes: [OrderTaxLine] = [],
                   customFields: [MetaData] = [],
                   giftCards: [OrderGiftCard] = []) -> Order {
        return Order.fake().copy(siteID: siteID,
                                 orderID: orderID,
                                 customerID: 11,
                                 orderKey: "abc123",
                                 number: "963",
                                 status: status,
                                 currency: "USD",
                                 customerNote: "",
                                 dateCreated: DateFormatter.dateFromString(with: "2018-04-03T23:05:12"),
                                 dateModified: DateFormatter.dateFromString(with: "2018-04-03T23:05:14"),
                                 datePaid: DateFormatter.dateFromString(with: "2018-04-03T23:05:14"),
                                 discountTotal: "30.00",
                                 discountTax: "1.20",
                                 shippingTotal: "0.00",
                                 shippingTax: "0.00",
                                 total: "31.20",
                                 totalTax: "1.20",
                                 paymentMethodID: "stripe",
                                 paymentMethodTitle: "Credit Card (Stripe)",
                                 items: items,
                                 billingAddress: sampleAddress(),
                                 shippingAddress: sampleAddress(),
                                 shippingLines: shippingLines,
                                 refunds: refunds,
                                 fees: fees,
                                 taxes: taxes,
                                 customFields: customFields,
                                 appliedGiftCards: giftCards)
    }

    func sampleOrder() -> Order {
        makeOrder()
    }

    func sampleOrderWithItems() -> Order {
        makeOrder(items: sampleOrderItems())
    }

    func orderWithFees() -> Order {
        makeOrder(fees: sampleFeeLines())
    }

    func orderWithFeesAndGiftCards() -> Order {
        makeOrder(fees: sampleFeeLines(),
                  giftCards: sampleGiftCards())
    }

    func orderPaidWithNoPaymentMethod() -> Order {
        return Order.fake().copy(
            datePaid: DateFormatter.dateFromString(with: "2018-04-03T23:05:14"),
            paymentMethodID: "",
            paymentMethodTitle: "")
    }

    func orderWithAPIRefunds() -> Order {
        makeOrder(refunds: refundsWithNegativeValue())
    }

    func orderWithTransientRefunds() -> Order {
        makeOrder(refunds: refundsWithPositiveValue())
    }

    func sampleOrderCreatedInCurrentYear() -> Order {
        return Order.fake().copy(siteID: siteID,
                                 orderID: orderID,
                                 customerID: 11,
                                 orderKey: "abc123",
                                 number: "963",
                                 status: .processing,
                                 currency: "USD",
                                 customerNote: "",
                                 datePaid: Date(),
                                 discountTotal: "30.00",
                                 discountTax: "1.20",
                                 shippingTotal: "0.00",
                                 shippingTax: "0.00",
                                 total: "31.20",
                                 totalTax: "1.20",
                                 paymentMethodID: "stripe",
                                 paymentMethodTitle: "Credit Card (Stripe)",
                                 billingAddress: sampleAddress(),
                                 shippingAddress: sampleAddress(),
                                 shippingLines: Self.sampleShippingLines())
    }

    static func sampleShippingLines(cost: String = "133.00", tax: String = "0.00") -> [ShippingLine] {
        return [ShippingLine(shippingID: 123,
        methodTitle: "International Priority Mail Express Flat Rate",
        methodID: "usps",
        total: cost,
        totalTax: tax,
        taxes: [])]
    }

    func sampleOrderItems() -> [OrderItem] {
        [
            OrderItem.fake().copy(itemID: 1, name: "Sample Item", productID: 12, quantity: 2, price: 123)
        ]
    }

    func sampleFeeLines() -> [OrderFeeLine] {
        return [
            sampleFeeLine()
        ]
    }

    func sampleFeeLine(amount: String = "100.00") -> OrderFeeLine {
        return OrderFeeLine(feeID: 1,
                            name: "Fee",
                            taxClass: "",
                            taxStatus: .none,
                            total: amount,
                            totalTax: "",
                            taxes: [],
                            attributes: [])
    }

    func sampleGiftCards() -> [OrderGiftCard] {
        let giftCard = OrderGiftCard(giftCardID: 2, code: "SU9F-MGB5-KS5V-EZFT", amount: 20)
        return [giftCard]
    }

    func sampleAddress() -> Address {
        return Address(firstName: "Johnny",
                       lastName: "Appleseed",
                       company: "",
                       address1: "234 70th Street",
                       address2: "",
                       city: "Niagara Falls",
                       state: "NY",
                       postcode: "14304",
                       country: "US",
                       phone: "333-333-3333",
                       email: "scrambled@scrambled.com")
    }

    /// An order with broken elements, inspired by `broken-order.json`
    ///
    func brokenOrder() -> Order {
        return Order.fake().copy(siteID: 545,
                                 orderID: 85,
                                 orderKey: "abc123",
                                 number: "85",
                                 status: .custom("draft"),
                                 currency: "GBP",
                                 customerNote: "",
                                 datePaid: nil, // there is no paid date
                                 discountTotal: "0.00",
                                 discountTax: "0.00",
                                 shippingTotal: "0.00",
                                 shippingTax: "0.00",
                                 total: "0.00",
                                 totalTax: "0.00",
                                 paymentMethodID: "",
                                 paymentMethodTitle: "", // broken in the sense that there should be a payment title
                                 billingAddress: brokenAddress(), // empty address
                                 shippingAddress: brokenAddress(),
                                 shippingLines: brokenShippingLines()) // empty shipping
    }

    /// An order with broken elements that hasn't been paid, inspired by `broken-order.json`
    ///
    func unpaidOrder() -> Order {
        return Order.fake().copy(siteID: 545,
                                 orderID: 85,
                                 orderKey: "abc123",
                                 number: "85",
                                 status: .custom("draft"),
                                 currency: "GBP",
                                 customerNote: "",
                                 datePaid: nil, // there is no paid date
                                 discountTotal: "0.00",
                                 discountTax: "0.00",
                                 shippingTotal: "0.00",
                                 shippingTax: "0.00",
                                 total: "0.00",
                                 totalTax: "0.00",
                                 paymentMethodID: "cod",
                                 paymentMethodTitle: "Cash on Delivery",
                                 billingAddress: brokenAddress(), // empty address
                                 shippingAddress: brokenAddress(),
                                 shippingLines: brokenShippingLines()) // empty shipping
    }

    /// An address that may or may not be broken, that came from `broken-order.json`
    ///
    func brokenAddress() -> Address {
        return Address(firstName: "",
                       lastName: "",
                       company: "",
                       address1: "",
                       address2: "",
                       city: "",
                       state: "",
                       postcode: "",
                       country: "",
                       phone: "",
                       email: "")
    }

    /// A shipping line that may or may not be broken, from `broken-order.json`
    ///
    func brokenShippingLines() -> [ShippingLine] {
        return [ShippingLine(shippingID: 1,
                            methodTitle: "Shipping",
                            methodID: "",
                            total: "0.00",
                            totalTax: "0.00",
                            taxes: [])]
    }

    func refundsWithNegativeValue() -> [OrderRefundCondensed] {
        return [
            OrderRefundCondensed(refundID: 0, reason: nil, total: "-1.2"),
        ]
    }

    func refundsWithPositiveValue() -> [OrderRefundCondensed] {
        return [
            OrderRefundCondensed(refundID: 0, reason: nil, total: "1.2"),
        ]
    }
}
