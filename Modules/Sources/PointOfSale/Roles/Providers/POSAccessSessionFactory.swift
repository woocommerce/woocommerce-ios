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
            authenticator: DefaultPOSPINAuthenticator(cache: cache, fetcher: fetcher, siteID: siteID),
            rateLimiter: POSLocalRateLimiter(siteID: siteID),
            cache: cache,
            fetcher: fetcher,
            siteID: siteID
        )
    }
}
