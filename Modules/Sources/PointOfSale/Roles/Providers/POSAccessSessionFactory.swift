import enum Experiments.FeatureFlag

@MainActor
enum POSAccessSessionFactory {
    static func make(siteID: Int64, featureFlags: POSFeatureFlagProviding) -> POSAccessSession {
        guard featureFlags.isFeatureFlagEnabled(.pointOfSaleRoles) else {
            return UnrestrictedPOSAccessSession()
        }
        return DefaultPOSAccessSession(
            siteID: siteID,
            authenticator: DefaultPOSPINAuthenticator(),
            rateLimiter: POSLocalRateLimiter(siteID: siteID)
        )
    }
}
