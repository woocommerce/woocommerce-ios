import Foundation

enum POSPINEntryState: Equatable {
    case idle
    case error(message: String)
    case lockout(until: Date)
    case loading
}
