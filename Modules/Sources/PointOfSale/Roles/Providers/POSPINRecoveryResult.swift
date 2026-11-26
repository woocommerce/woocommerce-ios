public enum POSPINRecoveryResult: Equatable, Sendable {
    case verified(siteID: Int64)
    case canceled
    case failed
}

typealias POSPINRecoveryAuthentication = @MainActor (Int64) async -> POSPINRecoveryResult
