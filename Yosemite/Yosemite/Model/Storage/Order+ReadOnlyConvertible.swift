import Foundation
import Storage


// MARK: - Storage.Order: ReadOnlyConvertible
//
extension Storage.Order: ReadOnlyConvertible {

    /// Updates the Storage.Order with the ReadOnly.
    ///
    public func update(with order: Yosemite.Order) {
        siteID = order.siteID
        orderID = order.orderID
        parentID = order.parentID
        customerID = order.customerID
        orderKey = order.orderKey
        isEditable = order.isEditable
        needsPayment = order.needsPayment
        needsProcessing = order.needsProcessing
        number = order.number
        statusKey = order.status.rawValue
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
        paymentMethodID = order.paymentMethodID
        paymentMethodTitle = order.paymentMethodTitle
        paymentURL = order.paymentURL as NSURL?
        chargeID = order.chargeID

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
        let orderItems = orderItemsArray.map { $0.toReadOnly() }
        let orderCoupons = coupons?.map { $0.toReadOnly() } ?? [Yosemite.OrderCouponLine]()
        let orderRefunds = refunds?.map { $0.toReadOnly() } ?? [Yosemite.OrderRefundCondensed]()
        let orderShippingLines = shippingLines?.map { $0.toReadOnly() } ?? [Yosemite.ShippingLine]()
        let orderFeeLines = fees?.map { $0.toReadOnly() } ?? [Yosemite.OrderFeeLine]()
        let orderTaxLines = taxes?.map { $0.toReadOnly() } ?? [Yosemite.OrderTaxLine]()
        let orderCustomFields = customFields?.map { $0.toReadOnly() } ?? [Yosemite.OrderMetaData]()

        return Order(siteID: siteID,
                     orderID: orderID,
                     parentID: parentID,
                     customerID: customerID,
                     orderKey: orderKey,
                     isEditable: isEditable,
                     needsPayment: needsPayment,
                     needsProcessing: needsPayment,
                     number: number ?? "",
                     status: OrderStatusEnum(rawValue: statusKey),
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
                     paymentMethodID: paymentMethodID ?? "",
                     paymentMethodTitle: paymentMethodTitle ?? "",
                     paymentURL: paymentURL as URL?,
                     chargeID: chargeID,
                     items: orderItems,
                     billingAddress: createReadOnlyBillingAddress(),
                     shippingAddress: createReadOnlyShippingAddress(),
                     shippingLines: orderShippingLines,
                     coupons: orderCoupons,
                     refunds: orderRefunds,
                     fees: orderFeeLines,
                     taxes: orderTaxLines,
                     customFields: orderCustomFields,
                     renewalSubscriptionID: nil)

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

extension Storage.Order {
     var orderItemsArray: [Storage.OrderItem] {
         return items?.toArray() ?? []
     }
 }
