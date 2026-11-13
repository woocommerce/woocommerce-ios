import enum Experiments.FeatureFlag

@MainActor
enum POSAccessSessionFactory {
    static func make(siteID: Int64,
                     featureFlags: POSFeatureFlagProviding) -> POSAccessSession {
        guard featureFlags.isFeatureFlagEnabled(.pointOfSaleRoles) else {
            return UnrestrictedPOSAccessSession()
        }
        let credentialProvider = POSLocalPINStore(siteID: siteID)
        return DefaultPOSAccessSession(
            siteID: siteID,
            authenticator: DefaultPOSPINAuthenticator(credentialProvider: credentialProvider),
            rateLimiter: POSLocalRateLimiter(siteID: siteID),
            credentialProvider: credentialProvider
        )
    }
}
