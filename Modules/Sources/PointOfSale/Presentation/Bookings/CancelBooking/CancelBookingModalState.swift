import Foundation

enum CancelBookingModalState: Identifiable, Equatable {
    case confirmation

    var id: String {
        switch self {
        case .confirmation: return "cancelConfirmation"
        }
    }
}
