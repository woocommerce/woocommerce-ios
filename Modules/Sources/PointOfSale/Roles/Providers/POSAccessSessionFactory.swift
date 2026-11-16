import Foundation
import enum Experiments.FeatureFlag

@MainActor
enum POSAccessSessionFactory {
    private static var rateLimiters: [Int64: POSLocalRateLimiter] = [:]

    static func make(siteID: Int64,
                     featureFlags: POSFeatureFlagProviding,
                     credentialProvider: POSPINCredentialProviding? = nil,
                     rateLimiter: POSLocalRateLimiter? = nil,
                     userDefaults: UserDefaults = .standard,
                     shouldCreate: @MainActor () -> Bool = { true }) async throws -> POSAccessSession {
        guard featureFlags.isFeatureFlagEnabled(.pointOfSaleRoles) else {
            return UnrestrictedPOSAccessSession()
        }
        let credentialProvider = credentialProvider ?? POSLocalPINStore(siteID: siteID)
        let limiter: POSLocalRateLimiter
        if let rateLimiter {
            limiter = rateLimiter
        } else {
            limiter = rateLimiters[siteID].flatMap { $0.isRetired ? nil : $0 } ?? POSLocalRateLimiter(siteID: siteID)
            rateLimiters[siteID] = limiter
        }
        try await limiter.pendingPINChanges.waitUntilEmpty()
        try Task.checkCancellation()
        guard shouldCreate() else { throw CancellationError() }
        return DefaultPOSAccessSession(
            siteID: siteID,
            authenticator: DefaultPOSPINAuthenticator(credentialProvider: credentialProvider),
            rateLimiter: limiter,
            credentialProvider: credentialProvider,
            userDefaults: userDefaults
        )
    }
}
