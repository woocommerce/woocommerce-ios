import Foundation
import struct Networking.Booking

extension BookingDetailsViewModel {
    struct PaymentContent {
        let amounts: [Amount]

        init(booking: Booking) {
            amounts = [
                .init(value: "$55.00", type: .service),
                .init(value: "$0", type: .tax),
                .init(value: "-", type: .discount),
                .init(value: "$55.00", type: .total, emphasized: true),
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
}
