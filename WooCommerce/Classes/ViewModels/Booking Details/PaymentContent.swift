import Foundation
import struct Networking.Booking
import class WooFoundationCore.CurrencyFormatter

extension BookingDetailsViewModel {
    final class PaymentContent: ObservableObject {
        @Published var amounts: [Amount] = []
        @Published var actions: [Action] = []

        func update(with booking: Booking) {
            let total = booking.orderInfo?.paymentInfo?.total ?? booking.cost
            let totalTax = booking.orderInfo?.paymentInfo?.totalTax ?? "0"
            let subtotal = booking.orderInfo?.paymentInfo?.subtotal ?? "0"
            let discount: String = {
                guard let totalDecimal = Decimal(string: total),
                      let subtotalDecimal = Decimal(string: subtotal) else {
                    return "-"
                }
                return (totalDecimal - subtotalDecimal).description
            }()

            amounts = [
                .init(value: BookingDetailsViewModel.formatPrice(for: booking, priceString: subtotal), type: .service),
                .init(value: BookingDetailsViewModel.formatPrice(for: booking, priceString: totalTax), type: .tax),
                .init(value: BookingDetailsViewModel.formatPrice(for: booking, priceString: discount), type: .discount),
                .init(value: BookingDetailsViewModel.formatPrice(for: booking, priceString: total), type: .total, emphasized: true),
            ]

            actions = [
                booking.isPaid && booking.hasAssociatedOrder ? .refund : nil,
                booking.hasAssociatedOrder ? .viewOrder : nil
            ].compactMap { $0 }
        }
    }
}

extension BookingDetailsViewModel.PaymentContent {
    struct Amount {
        enum AmountType {
            case service
            case tax
            case discount
            case total
        }

        let value: String
        let type: AmountType
        let emphasized: Bool

        var title: String {
            return type.rowTitle
        }

        init(value: String, type: AmountType, emphasized: Bool = false) {
            self.value = value
            self.type = type
            self.emphasized = emphasized
        }
    }
}

extension BookingDetailsViewModel.PaymentContent.Amount: Identifiable {
    var id: String {
        return title
    }
}

extension BookingDetailsViewModel.PaymentContent.Amount.AmountType {
    var rowTitle: String {
        switch self {
        case .service:
            return Localization.paymentServiceRowTitle
        case .tax:
            return Localization.paymentTaxRowTitle
        case .discount:
            return Localization.paymentDiscountRowTitle
        case .total:
            return Localization.paymentTotalRowTitle
        }
    }
}

extension BookingDetailsViewModel.PaymentContent {
    enum Action: String, Identifiable {
        case refund
        case viewOrder

        var id: String {
            return rawValue
        }
    }
}

extension BookingDetailsViewModel.PaymentContent.Action {
    var buttonTitle: String {
        switch self {
        case .refund:
            return Localization.paymentRefundButtonTitle
        case .viewOrder:
            return Localization.paymentViewOrderButtonTitle
        }
    }
}

private enum Localization {
    static let paymentServiceRowTitle = NSLocalizedString(
        "BookingDetailsView.payment.serviceRow.title",
        value: "Service",
        comment: "Service row title in payment section in booking details view."
    )

    static let paymentTaxRowTitle = NSLocalizedString(
        "BookingDetailsView.payment.taxRow.title",
        value: "Tax",
        comment: "Tax row title in payment section in booking details view."
    )

    static let paymentDiscountRowTitle = NSLocalizedString(
        "BookingDetailsView.payment.discountRow.title",
        value: "Discount",
        comment: "Discount row title in payment section in booking details view."
    )

    static let paymentTotalRowTitle = NSLocalizedString(
        "BookingDetailsView.payment.totalRow.title",
        value: "Total",
        comment: "Total row title in payment section in booking details view."
    )

    static let paymentRefundButtonTitle = NSLocalizedString(
        "BookingDetailsView.payment.refund.title",
        value: "Refund",
        comment: "Title for 'Refund' button in payment section in booking details view."
    )

    static let paymentViewOrderButtonTitle = NSLocalizedString(
        "BookingDetailsView.payment.viewOrder.title",
        value: "View order",
        comment: "Title for 'View order' button in payment section in booking details view."
    )
}
