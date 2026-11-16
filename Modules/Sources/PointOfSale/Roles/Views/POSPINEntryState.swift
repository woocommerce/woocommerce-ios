import Foundation

enum POSPINErrorKind: Equatable {
    case invalidPIN
    case generic
}

enum POSPINEntryState: Equatable {
    case idle
    case error(kind: POSPINErrorKind)
    case waiting(remainingSeconds: Int)
    case unavailable
    /// Keys stay disabled without the loading animation while the first lockout check runs.
    case checking
    case loading
}
