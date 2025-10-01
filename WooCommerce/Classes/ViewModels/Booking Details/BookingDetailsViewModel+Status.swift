import Foundation
import SwiftUI

extension BookingDetailsViewModel {
    enum Status {
        case booked, paid, payAtLocation
    }
}

extension BookingDetailsViewModel.Status {
    var labelText: String {
        switch self {
        case .booked:
            return Localization.bookingStatusBooked
        case .paid:
            return Localization.bookingStatusPaid
        case .payAtLocation:
            return Localization.bookingStatusPayAtLocation
        }
    }

    var labelColor: Color {
        switch self {
        case .booked:
            return Color(UIColor.systemGray6)
        case .paid:
            return Color(UIColor.systemGray6)
        case .payAtLocation:
            return Color(UIColor(hexString: "FFE365"))
        }
    }
}

private extension BookingDetailsViewModel.Status {
    enum Localization {
        static let bookingStatusBooked = NSLocalizedString(
            "BookingDetailsView.statusLabel.booked",
            value: "Booked",
            comment: "Title for the 'Booked' status label in the header view."
        )

        static let bookingStatusPaid = NSLocalizedString(
            "BookingDetailsView.statusLabel.paid",
            value: "Paid",
            comment: "Title for the 'Paid' status label in the header view."
        )

        static let bookingStatusPayAtLocation = NSLocalizedString(
            "BookingDetailsView.statusLabel.payAtLocation",
            value: "Pay at location",
            comment: "Title for the 'Pay at location' status label in the header view."
        )
    }
}
