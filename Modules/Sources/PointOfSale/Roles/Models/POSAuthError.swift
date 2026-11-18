import Foundation

enum POSAuthError: Error, Equatable {
    case invalidPIN
    case rateLimited(remainingSeconds: Int)
    case unknown
}
