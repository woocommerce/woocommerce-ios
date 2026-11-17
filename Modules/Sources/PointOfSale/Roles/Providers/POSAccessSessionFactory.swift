import Foundation
import enum Experiments.FeatureFlag

@MainActor
enum POSAccessSessionFactory {
    private static var rateLimiters: [Int64: POSLocalRateLimiter] = [:]
    /// In memory only: a relaunch never resumes an operator, so POS opens locked after the app is killed.
    private static var unlockedStaff: [Int64: POSStaff] = [:]

    static func make(siteID: Int64,
                     featureFlags: POSFeatureFlagProviding,
                     credentialProvider: POSPINCredentialProviding? = nil,
                     rateLimiter: POSLocalRateLimiter? = nil,
                     userDefaults: UserDefaults = .standard,
                     locksWhenPOSOpens: Bool = true,
                     shouldCreate: @MainActor () -> Bool = { true }) async throws -> POSAccessSession {
        guard featureFlags.isFeatureFlagEnabled(.pointOfSaleRoles) else {
            return UnrestrictedPOSAccessSession()
        }
        let credentialProvider = credentialProvider ?? POSLocalPINStore(siteID: siteID)
        let limiter: POSLocalRateLimiter
        if let rateLimiter {
            limiter = rateLimiter
        } else {
            if let current = rateLimiters[siteID], !current.isRetired {
                limiter = current
            } else {
                // A retired limiter means the PIN setup was cleared, for example on logout.
                limiter = POSLocalRateLimiter(siteID: siteID)
                rateLimiters[siteID] = limiter
                unlockedStaff[siteID] = nil
            }
        }
        try await limiter.pendingPINChanges.waitUntilEmpty()
        try Task.checkCancellation()
        guard shouldCreate() else { throw CancellationError() }
        let resumingStaff = unlockedStaff.removeValue(forKey: siteID)
        return DefaultPOSAccessSession(
            siteID: siteID,
            authenticator: DefaultPOSPINAuthenticator(credentialProvider: credentialProvider),
            rateLimiter: limiter,
            credentialProvider: credentialProvider,
            userDefaults: userDefaults,
            resumingStaff: locksWhenPOSOpens ? nil : resumingStaff,
            onEnd: { staff in unlockedStaff[siteID] = staff }
        )
    }
}
