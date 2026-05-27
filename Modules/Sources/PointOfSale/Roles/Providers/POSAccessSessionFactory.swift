import enum Experiments.FeatureFlag
import struct Networking.POSStaffMember

@MainActor
enum POSAccessSessionFactory {
    static func make(siteID: Int64, featureFlags: POSFeatureFlagProviding) -> POSAccessSession {
        guard featureFlags.isFeatureFlagEnabled(.pointOfSaleRoles) else {
            return UnrestrictedPOSAccessSession()
        }
        let cache = POSStaffCache()
        // NullPOSStaffFetcher is a placeholder until Chunk 7 wires the real POSStaffAdaptor.
        let fetcher = NullPOSStaffFetcher()
        return DefaultPOSAccessSession(
            authenticator: DefaultPOSPINAuthenticator(cache: cache, fetcher: fetcher, siteID: siteID),
            rateLimiter: POSLocalRateLimiter(siteID: siteID),
            cache: cache,
            fetcher: fetcher,
            siteID: siteID
        )
    }
}

/// Placeholder fetcher that always reports a transient error.
/// Replaced in Chunk 7 when POSStaffAdaptor lands in the app target.
private struct NullPOSStaffFetcher: POSStaffFetching {
    func fetchStaff(siteID: Int64) async throws(POSStaffFetchError) -> [POSStaffMember] {
        throw .transient(retryable: false)
    }
}
