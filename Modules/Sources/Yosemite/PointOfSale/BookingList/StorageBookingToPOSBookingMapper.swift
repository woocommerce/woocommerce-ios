import Foundation
import class WooFoundationCore.CurrencyFormatter
import Storage

struct StorageBookingToPOSBookingMapper {
    private let currencyFormatter: CurrencyFormatter
    private let siteSettings: [SiteSetting]

    init(currencyFormatter: CurrencyFormatter, siteSettings: [SiteSetting] = []) {
        self.currencyFormatter = currencyFormatter
        self.siteSettings = siteSettings
    }

    func map(booking: Yosemite.Booking, resource: BookingResource?) -> POSBooking? {
        guard let orderInfo = booking.orderInfo else {
            return nil
        }

        let posOrder = buildPOSOrder(from: orderInfo, booking: booking)

        let billingAddress = orderInfo.customerInfo?.billingAddress

        let customerName: String? = {
            guard let billingAddress else { return nil }
            let fullName = [billingAddress.firstName, billingAddress.lastName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            return fullName.isEmpty ? nil : fullName
        }()

        let serviceName = orderInfo.productInfo?.name ?? ""

        let formattedAmount = currencyFormatter.formatAmount(booking.cost, with: booking.currency) ?? booking.cost

        let orderID: Int64? = booking.orderID != 0 ? booking.orderID : nil

        let formattedBillingAddress: String? = {
            guard let billingAddress else { return nil }
            let parts = [billingAddress.address1, billingAddress.city, billingAddress.state, billingAddress.postcode]
                .filter { !$0.isEmpty }
            return parts.isEmpty ? nil : parts.joined(separator: ", ")
        }()

        let location: String? = {
            let siteAddress = SiteAddress(siteSettings: siteSettings)
            let parts = [siteAddress.address, siteAddress.city, siteAddress.state, siteAddress.postalCode]
                .filter { !$0.isEmpty }
            return parts.isEmpty ? nil : parts.joined(separator: ", ")
        }()

        let duration = POSBookingMapper.formatDuration(from: booking.startDate, to: booking.endDate)

        let formattedSubtotal = orderInfo.paymentInfo.flatMap {
            currencyFormatter.formatAmount($0.subtotal, with: booking.currency)
        }
        let formattedTax = orderInfo.paymentInfo.flatMap {
            currencyFormatter.formatAmount($0.totalTax, with: booking.currency)
        }

        return POSBooking(
            id: booking.bookingID,
            customerName: customerName,
            serviceName: serviceName,
            startDate: booking.startDate,
            endDate: booking.endDate,
            formattedAmount: formattedAmount,
            status: booking.bookingStatus,
            attendanceStatus: booking.attendanceStatus,
            orderID: orderID,
            resourceName: resource?.name,
            resourceImageURL: resource?.imageURL,
            customerEmail: billingAddress?.email.flatMap { $0.isEmpty ? nil : $0 },
            customerPhone: billingAddress?.phone.flatMap { $0.isEmpty ? nil : $0 },
            billingAddress: formattedBillingAddress,
            customerNote: orderInfo.customerInfo?.note.flatMap { $0.isEmpty ? nil : $0 },
            bookingNote: booking.note.isEmpty ? nil : booking.note,
            location: location,
            duration: duration,
            formattedSubtotal: formattedSubtotal,
            formattedTax: formattedTax,
            order: posOrder
        )
    }
}

private extension StorageBookingToPOSBookingMapper {
    func buildPOSOrder(from orderInfo: BookingOrderInfo, booking: Booking) -> POSOrder {
        let formattedTotal = orderInfo.paymentInfo.flatMap {
            currencyFormatter.formatAmount($0.total, with: booking.currency)
        } ?? ""

        let formattedSubtotal = orderInfo.paymentInfo.flatMap {
            currencyFormatter.formatAmount($0.subtotal, with: booking.currency)
        } ?? ""

        let formattedTotalTax = orderInfo.paymentInfo.flatMap {
            currencyFormatter.formatAmount($0.totalTax, with: booking.currency)
        } ?? ""

        let formattedDiscountTotal: String? = {
            guard let value = Double(orderInfo.discountTotal), value > 0 else { return nil }
            return currencyFormatter.formatAmount(orderInfo.discountTotal, with: booking.currency, isNegative: true)
        }()

        let posLineItems: [POSOrderItem] = orderInfo.lineItems.compactMap { item in
            guard let formattedPrice = currencyFormatter.formatAmount(item.price as Decimal, with: booking.currency),
                  let formattedTotal = currencyFormatter.formatAmount(item.total, with: booking.currency) else {
                return nil
            }
            let total = Decimal(string: item.total) ?? (item.price as Decimal) * item.quantity
            let totalTax = Decimal(string: item.totalTax) ?? 0
            return POSOrderItem(
                itemID: item.itemID,
                name: item.name,
                quantity: item.quantity,
                price: item.price as Decimal,
                total: total,
                totalTax: totalTax,
                formattedPrice: formattedPrice,
                formattedTotal: formattedTotal,
                imageSrc: item.imageSrc,
                attributes: []
            )
        }

        let posRefunds: [POSOrderRefund] = orderInfo.refunds.map { refund in
            POSOrderRefund(
                refundID: refund.refundID,
                formattedTotal: currencyFormatter.formatAmount(refund.total, with: booking.currency) ?? "",
                reason: refund.reason
            )
        }

        let formattedNetAmount: String? = {
            guard !orderInfo.refunds.isEmpty,
                  let totalDecimal = Decimal(string: orderInfo.paymentInfo?.total ?? "") else {
                return nil
            }
            let refundSum = orderInfo.refunds.reduce(Decimal.zero) { acc, refund in
                acc + (Decimal(string: refund.total) ?? 0)
            }
            let netAmount = totalDecimal + refundSum
            return currencyFormatter.formatAmount(netAmount, with: booking.currency)
        }()

        let lineItemQuantitiesByProductOrVariationID = orderInfo.lineItems.reduce(into: [Int64: Decimal]()) { acc, item in
            let id = item.variationID != 0 ? item.variationID : item.productID
            acc[id, default: 0] += item.quantity
        }

        return POSOrder(
            id: orderInfo.orderID,
            number: orderInfo.orderNumber,
            dateCreated: orderInfo.dateCreated,
            status: .init(rawValue: orderInfo.statusKey),
            formattedTotal: formattedTotal,
            formattedSubtotal: formattedSubtotal,
            customerEmail: orderInfo.customerEmail,
            paymentMethodID: orderInfo.paymentInfo?.paymentMethodID ?? "",
            paymentMethodTitle: orderInfo.paymentInfo?.paymentMethodTitle ?? "",
            lineItems: posLineItems,
            refunds: posRefunds,
            formattedDiscountTotal: formattedDiscountTotal,
            formattedTotalTax: formattedTotalTax,
            formattedPaymentTotal: formattedTotal,
            formattedNetAmount: formattedNetAmount,
            datePaid: orderInfo.datePaid,
            lineItemQuantitiesByProductOrVariationID: lineItemQuantitiesByProductOrVariationID
        )
    }
}
