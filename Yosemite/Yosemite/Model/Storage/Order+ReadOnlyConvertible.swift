import Foundation
import Storage


// MARK: - Storage.Order: ReadOnlyConvertible
//
extension Storage.Order: ReadOnlyConvertible {

    /// Updates the Storage.Order with the ReadOnly.
    ///
    public func update(with order: Yosemite.Order) {
        siteID = Int64(order.siteID)
        orderID = Int64(order.orderID)
        parentID = Int64(order.parentID)
        customerID = Int64(order.customerID)
        number = order.number
        statusKey = order.statusKey
        currency = order.currency
        customerNote = order.customerNote

        dateCreated = order.dateCreated
        dateModified = order.dateModified
        datePaid = order.datePaid

        discountTotal = order.discountTotal
        discountTax = order.discountTax
        shippingTotal = order.shippingTotal
        shippingTax = order.shippingTax

        total = order.total
        totalTax = order.totalTax
        paymentMethodTitle = order.paymentMethodTitle

        if let billingAddress = order.billingAddress {
            billingFirstName = billingAddress.firstName
            billingLastName = billingAddress.lastName
            billingCompany = billingAddress.company
            billingAddress1 = billingAddress.address1
            billingAddress2 = billingAddress.address2
            billingCity = billingAddress.city
            billingState = billingAddress.state
            billingPostcode = billingAddress.postcode
            billingCountry = billingAddress.country
            billingPhone = billingAddress.phone
            billingEmail = billingAddress.email
        }

        if let shippingAddress = order.shippingAddress {
            shippingFirstName = shippingAddress.firstName
            shippingLastName = shippingAddress.lastName
            shippingCompany = shippingAddress.company
            shippingAddress1 = shippingAddress.address1
            shippingAddress2 = shippingAddress.address2
            shippingCity = shippingAddress.city
            shippingState = shippingAddress.state
            shippingPostcode = shippingAddress.postcode
            shippingCountry = shippingAddress.country
            shippingPhone = shippingAddress.phone
            shippingEmail = shippingAddress.email
        }
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.Order {
        let orderItems = items?.map { $0.toReadOnly() } ?? [Yosemite.OrderItem]()
        let orderCoupons = coupons?.map { $0.toReadOnly() } ?? [Yosemite.OrderCouponLine]()
        let orderRefunds = refunds?.map { $0.toReadOnly() } ?? [Yosemite.OrderRefundCondensed]()
        let orderShippingLines = shippingLines?.map { $0.toReadOnly() } ?? [Yosemite.ShippingLine]()

        return Order(siteID: Int(siteID),
                     orderID: Int(orderID),
                     parentID: Int(parentID),
                     customerID: Int(customerID),
                     number: number ?? "",
                     statusKey: statusKey,
                     currency: currency ?? "",
                     customerNote: customerNote ?? "",
                     dateCreated: dateCreated ?? Date(),
                     dateModified: dateModified ?? Date(),
                     datePaid: datePaid,
                     discountTotal: discountTotal ?? "",
                     discountTax: discountTax ?? "",
                     shippingTotal: shippingTotal ?? "",
                     shippingTax: shippingTax ?? "",
                     total: total ?? "",
                     totalTax: totalTax ?? "",
                     paymentMethodTitle: paymentMethodTitle ?? "",
                     items: orderItems,
                     billingAddress: createReadOnlyBillingAddress(),
                     shippingAddress: createReadOnlyShippingAddress(),
                     shippingLines: orderShippingLines,
                     coupons: orderCoupons,
                     refunds: orderRefunds)
    }


    // MARK: - Private Helpers

    private func createReadOnlyBillingAddress() -> Yosemite.Address? {
        guard let billingCountry = billingCountry else {
            return nil
        }

        return Address(firstName: billingFirstName ?? "",
                       lastName: billingLastName ?? "",
                       company: billingCompany ?? "",
                       address1: billingAddress1 ?? "",
                       address2: billingAddress2 ?? "",
                       city: billingCity ?? "",
                       state: billingState ?? "",
                       postcode: billingPostcode ?? "",
                       country: billingCountry,
                       phone: billingPhone,
                       email: billingEmail)
    }

    private func createReadOnlyShippingAddress() -> Yosemite.Address? {
        guard let shippingCountry = shippingCountry else {
            return nil
        }

        return Address(firstName: shippingFirstName ?? "",
                       lastName: shippingLastName ?? "",
                       company: shippingCompany ?? "",
                       address1: shippingAddress1 ?? "",
                       address2: shippingAddress2 ?? "",
                       city: shippingCity ?? "",
                       state: shippingState ?? "",
                       postcode: shippingPostcode ?? "",
                       country: shippingCountry,
                       phone: shippingPhone,
                       email: shippingEmail)
    }
}
