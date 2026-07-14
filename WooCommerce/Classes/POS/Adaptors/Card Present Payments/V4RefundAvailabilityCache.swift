import Foundation

/// Caches, per site for the app session, whether the store exposes the v4 refund endpoints.
///
/// Keyed by site ID so switching stores never reuses a stale result. A `nil` entry means "not yet
/// determined" (probe needed); `true`/`false` are the cached outcomes of a probe. The cache is only
/// marked unavailable on a genuine "route not registered" response, so a transient per-order error
/// never disables v4 for the rest of the session.
///
@MainActor
final class V4RefundAvailabilityCache {

    /// App-session-shared instance. Site-keyed, so it is safe to keep for the whole session.
    static let shared = V4RefundAvailabilityCache()

    private var availabilityBySiteID: [Int64: Bool] = [:]

    init() {}

    /// Returns `true`/`false` once determined, or `nil` if v4 availability hasn't been probed yet.
    func isV4Available(siteID: Int64) -> Bool? {
        availabilityBySiteID[siteID]
    }

    func markV4Available(siteID: Int64) {
        availabilityBySiteID[siteID] = true
    }

    func markV4Unavailable(siteID: Int64) {
        availabilityBySiteID[siteID] = false
    }
}
