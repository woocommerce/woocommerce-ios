import Foundation

public enum POSAuthError: Error, Equatable {
    case invalidPIN
    case rateLimited(until: Date)
    case permanentlyLocked
    case unknown
}
