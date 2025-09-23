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
            return "Booked"
        case .paid:
            return "Paid"
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
