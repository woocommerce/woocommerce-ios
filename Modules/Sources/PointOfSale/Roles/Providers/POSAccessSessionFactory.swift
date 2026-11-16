import enum Experiments.FeatureFlag

@MainActor
enum POSAccessSessionFactory {
    private static var rateLimiters: [Int64: POSLocalRateLimiter] = [:]

    static func make(siteID: Int64,
                     featureFlags: POSFeatureFlagProviding) -> POSAccessSession {
        guard featureFlags.isFeatureFlagEnabled(.pointOfSaleRoles) else {
            return UnrestrictedPOSAccessSession()
        }
        let credentialProvider = POSLocalPINStore(siteID: siteID)
        let limiter = rateLimiters[siteID] ?? POSLocalRateLimiter(siteID: siteID)
        rateLimiters[siteID] = limiter
        return DefaultPOSAccessSession(
            siteID: siteID,
            authenticator: DefaultPOSPINAuthenticator(credentialProvider: credentialProvider),
            rateLimiter: limiter,
            credentialProvider: credentialProvider
        )
    }
}
