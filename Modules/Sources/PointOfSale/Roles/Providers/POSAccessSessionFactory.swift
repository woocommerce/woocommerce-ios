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
            try Task.checkCancellation()
            guard shouldCreate() else { throw CancellationError() }
            return UnrestrictedPOSAccessSession()
        }
        let credentialProvider = credentialProvider ?? POSLocalPINStore(siteID: siteID)
        let limiter: POSLocalRateLimiter
        if let rateLimiter {
            limiter = rateLimiter
        } else {
            limiter = rateLimiters[siteID] ?? POSLocalRateLimiter(siteID: siteID)
            rateLimiters[siteID] = limiter
        }
        // Registering a PIN save and claiming its replacement both run on MainActor.
        // Never expose a no-PIN session while an accepted first setup can still commit.
        while limiter.context.hasPendingPINChanges { try await Task.sleep(for: .milliseconds(50)) }
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
