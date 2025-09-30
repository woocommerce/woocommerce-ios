import Foundation
import struct Networking.Booking

extension BookingDetailsViewModel {
    struct PaymentContent {
        let amounts: [Amount]
        let actions: [Action]

        init(booking: Booking) {
            amounts = [
                .init(value: booking.cost, type: .service),
                .init(value: "$0", type: .tax),
                .init(value: "-", type: .discount),
                .init(value: "$55.00", type: .total, emphasized: true),
            ]

            actions = [
                .markAsPaid,
                .viewOrder
            ]
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
        case markAsPaid
        case markAsRefunded
        case viewOrder

        var id: String {
            return rawValue
        }
    }
}

extension BookingDetailsViewModel.PaymentContent.Action {
    var buttonTitle: String {
        switch self {
        case .markAsPaid:
            return Localization.paymentMarkAsPaidButtonTitle
        case .markAsRefunded:
            return Localization.paymentMarkAsRefundedButtonTitle
        case .viewOrder:
            return Localization.paymentViewOrderButtonTitle
        }
    }

    var isEmphasized: Bool {
        switch self {
        case .markAsPaid:
            return true
        case .markAsRefunded, .viewOrder:
            return false
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

    static let paymentMarkAsPaidButtonTitle = NSLocalizedString(
        "BookingDetailsView.payment.markAsPaid.title",
        value: "Mark as paid",
        comment: "Title for 'Mark as paid' button in payment section in booking details view."
    )

    static let paymentMarkAsRefundedButtonTitle = NSLocalizedString(
        "BookingDetailsView.payment.markAsRefunded.title",
        value: "Mark as refunded",
        comment: "Title for 'Mark as refunded' button in payment section in booking details view."
    )

    static let paymentViewOrderButtonTitle = NSLocalizedString(
        "BookingDetailsView.payment.viewOrder.title",
        value: "View order",
        comment: "Title for 'View order' button in payment section in booking details view."
    )
}
