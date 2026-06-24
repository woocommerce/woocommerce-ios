import enum Experiments.FeatureFlag

@MainActor
enum POSAccessSessionFactory {
    static func make(siteID: Int64,
                     featureFlags: POSFeatureFlagProviding,
                     fetcher: POSStaffFetching) -> POSAccessSession {
        guard featureFlags.isFeatureFlagEnabled(.pointOfSaleRoles) else {
            return UnrestrictedPOSAccessSession()
        }
        let cache = POSStaffCache()
        return DefaultPOSAccessSession(
            siteID: siteID,
            authenticator: DefaultPOSPINAuthenticator(cache: cache, siteID: siteID),
            rateLimiter: POSLocalRateLimiter(siteID: siteID),
            cache: cache,
            fetcher: fetcher
        )
    }
}
