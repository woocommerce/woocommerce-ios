import Yosemite

final class MockOrders {
    let siteID: Int64 = 1234
    let orderID: Int64 = 5678

    func makeOrder(status: OrderStatusEnum = .processing, items: [OrderItem] = []) -> Order {
        return Order(siteID: siteID,
                     orderID: orderID,
                     parentID: 0,
                     customerID: 11,
                     number: "963",
                     status: status,
                     currency: "USD",
                     customerNote: "",
                     dateCreated: date(with: "2018-04-03T23:05:12"),
                     dateModified: date(with: "2018-04-03T23:05:14"),
                     datePaid: date(with: "2018-04-03T23:05:14"),
                     discountTotal: "30.00",
                     discountTax: "1.20",
                     shippingTotal: "0.00",
                     shippingTax: "0.00",
                     total: "31.20",
                     totalTax: "1.20",
                     paymentMethodTitle: "Credit Card (Stripe)",
                     items: items,
                     billingAddress: sampleAddress(),
                     shippingAddress: sampleAddress(),
                     shippingLines: sampleShippingLines(),
                     coupons: [],
                     refunds: [])
    }

    func sampleOrder() -> Order {
        makeOrder()
    }

    func sampleOrderCreatedInCurrentYear() -> Order {
        return Order(siteID: siteID,
                     orderID: orderID,
                     parentID: 0,
                     customerID: 11,
                     number: "963",
                     status: .processing,
                     currency: "USD",
                     customerNote: "",
                     dateCreated: Date(),
                     dateModified: Date(),
                     datePaid: Date(),
                     discountTotal: "30.00",
                     discountTax: "1.20",
                     shippingTotal: "0.00",
                     shippingTax: "0.00",
                     total: "31.20",
                     totalTax: "1.20",
                     paymentMethodTitle: "Credit Card (Stripe)",
                     items: [],
                     billingAddress: sampleAddress(),
                     shippingAddress: sampleAddress(),
                     shippingLines: sampleShippingLines(),
                     coupons: [],
                     refunds: [])
    }

    func sampleShippingLines() -> [ShippingLine] {
        return [ShippingLine(shippingID: 123,
        methodTitle: "International Priority Mail Express Flat Rate",
        methodID: "usps",
        total: "133.00",
        totalTax: "0.00")]
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
        return Order(siteID: 545,
                     orderID: 85,
                     parentID: 0,
                     customerID: 0,
                     number: "85",
                     status: .custom("draft"),
                     currency: "GBP",
                     customerNote: "",
                     dateCreated: Date(),
                     dateModified: Date(),
                     datePaid: nil, // there is no paid date
                     discountTotal: "0.00",
                     discountTax: "0.00",
                     shippingTotal: "0.00",
                     shippingTax: "0.00",
                     total: "0.00",
                     totalTax: "0.00",
                     paymentMethodTitle: "", // broken in the sense that there should be a payment title
                     items: [],
                     billingAddress: brokenAddress(), // empty address
                     shippingAddress: brokenAddress(),
                     shippingLines: brokenShippingLines(), // empty shipping
                     coupons: [],
                     refunds: [])
    }

    /// An order with broken elements that hasn't been paid, inspired by `broken-order.json`
    ///
    func unpaidOrder() -> Order {
        return Order(siteID: 545,
                     orderID: 85,
                     parentID: 0,
                     customerID: 0,
                     number: "85",
                     status: .custom("draft"),
                     currency: "GBP",
                     customerNote: "",
                     dateCreated: Date(),
                     dateModified: Date(),
                     datePaid: nil, // there is no paid date
                     discountTotal: "0.00",
                     discountTax: "0.00",
                     shippingTotal: "0.00",
                     shippingTax: "0.00",
                     total: "0.00",
                     totalTax: "0.00",
                     paymentMethodTitle: "Cash on Delivery",
                     items: [],
                     billingAddress: brokenAddress(), // empty address
                     shippingAddress: brokenAddress(),
                     shippingLines: brokenShippingLines(), // empty shipping
                     coupons: [],
                     refunds: [])
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
                            totalTax: "0.00")]
    }

    /// Converts a date string to a date type
    ///
    func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }
}
