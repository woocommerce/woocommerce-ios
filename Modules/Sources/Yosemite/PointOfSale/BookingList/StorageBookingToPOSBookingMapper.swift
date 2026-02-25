import Foundation
import class WooFoundationCore.CurrencyFormatter
import Storage

struct StorageBookingToPOSBookingMapper {
    private let currencyFormatter: CurrencyFormatter
    private let orderMapper: POSOrderMapper
    private let siteSettings: [SiteSetting]

    init(currencyFormatter: CurrencyFormatter, siteSettings: [SiteSetting] = []) {
        self.currencyFormatter = currencyFormatter
        self.orderMapper = POSOrderMapper(currencyFormatter: currencyFormatter)
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

        let posLineItems: [POSOrderItem] = orderInfo.lineItems.compactMap { item in
            do {
                return try orderMapper.mapLineItem(
                    itemID: item.itemID,
                    name: item.name,
                    quantity: item.quantity,
                    price: item.price,
                    total: item.total,
                    totalTax: item.totalTax,
                    imageSrc: item.imageSrc,
                    attributes: [],
                    currency: booking.currency
                )
            } catch {
                DDLogError("⚠️ Failed to map BookingOrderLineItem \(item.itemID): \(error)")
                return nil
            }
        }

        let posRefunds = orderInfo.refunds.map { refund in
            orderMapper.mapRefund(refundID: refund.refundID, total: refund.total, reason: refund.reason, currency: booking.currency)
        }

        let formattedDiscountTotal = orderMapper.formatDiscountTotal(orderInfo.discountTotal, currency: booking.currency)

        let formattedNetAmount: String? = {
            guard !orderInfo.refunds.isEmpty else {
                return nil
            }
            return orderMapper.formatNetAmount(
                total: orderInfo.paymentInfo?.total ?? "",
                refundTotals: orderInfo.refunds.map(\.total),
                currency: booking.currency
            )
        }()

        let lineItemQuantitiesByProductOrVariationID = POSOrderMapper.aggregateLineItemQuantities(
            items: orderInfo.lineItems.map { ($0.productID, $0.variationID, $0.quantity) }
        )

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
            formattedPaymentTotal: orderInfo.datePaid != nil
                ? formattedTotal
                : (currencyFormatter.formatAmount("0.00", with: booking.currency) ?? ""),
            formattedNetAmount: formattedNetAmount,
            datePaid: orderInfo.datePaid,
            lineItemQuantitiesByProductOrVariationID: lineItemQuantitiesByProductOrVariationID
        )
    }
}
