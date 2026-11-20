import SwiftUI

enum POSPINErrorKind: Equatable {
    case invalidPIN
    case generic
}

enum POSPINEntryState: Equatable {
    case idle
    case error(kind: POSPINErrorKind)
    case waiting(remainingSeconds: Int)
    case unavailable
    case checkingLockout
    case loading
}

/// One entry step of a setup flow. A new ID starts an empty entry whose dots slide in from `edge`.
struct POSPINEntryPage: Equatable {
    let id: Int
    let edge: HorizontalEdge
}
