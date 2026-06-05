import Foundation

enum POSPINErrorKind: Equatable {
    case invalidPIN
    case generic
}

enum POSPINEntryState: Equatable {
    case idle
    case error(kind: POSPINErrorKind)
    case lockout(until: Date)
    case loading
}
