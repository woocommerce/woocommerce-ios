import Foundation
import SwiftUI

extension BookingDetailsViewModel {
    enum Status {
        case booked, paid
    }
}

extension BookingDetailsViewModel.Status {
    var labelText: String {
        switch self {
        case .booked:
            return Localization.bookingStatusBooked
        case .paid:
            return Localization.bookingStatusPaid
        }
    }

    var labelColor: Color {
        switch self {
        case .booked:
            return Color(UIColor.systemGray6)
        case .paid:
            return Color(UIColor.systemGray6)
        }
    }
}

private extension BookingDetailsViewModel.Status {
    enum Localization {
        static let bookingStatusBooked = NSLocalizedString(
            "BookingDetailsView.appointmentDetails.statusLabel.booked",
            value: "Booked",
            comment: "Title for the 'Booked' status label in the appointment details view."
        )

        static let bookingStatusPaid = NSLocalizedString(
            "BookingDetailsView.appointmentDetails.statusLabel.paid",
            value: "Paid",
            comment: "Title for the 'Paid' status label in the appointment details view."
        )
    }
}
