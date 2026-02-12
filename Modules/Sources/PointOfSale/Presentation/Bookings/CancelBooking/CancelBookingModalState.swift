import Foundation

enum CancelBookingModalState: Identifiable, Equatable {
    case confirmation
    case processing
    case success
    case error

    var id: String {
        switch self {
        case .confirmation: return "cancelConfirmation"
        case .processing:   return "cancelProcessing"
        case .success:      return "cancelSuccess"
        case .error:        return "cancelError"
        }
    }
}
