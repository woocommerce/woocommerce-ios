import Foundation

enum UpdateAttendanceModalState: Identifiable, Equatable {
    case confirmation
    case processing
    case success
    case error

    var id: String {
        switch self {
        case .confirmation: return "attendanceConfirmation"
        case .processing:   return "attendanceProcessing"
        case .success:      return "attendanceSuccess"
        case .error:        return "attendanceError"
        }
    }
}
