import Foundation

/// Caches, per site for the app session, whether the store exposes the v4 refund endpoints.
///
/// Keyed by site ID so switching stores never reuses a stale result. Application-password
/// (non-Jetpack) sites all share the same placeholder site ID, so nonpositive IDs are never
/// cached — those stores probe on every preview rather than risk one store's verdict leaking
/// into another's. A `nil` entry means "not yet determined" (probe needed); `true`/`false` are
/// the cached outcomes of a probe. Only a genuine "route not registered" probe response marks a
/// site unavailable, so a transient per-order error (or a stale locally-cached WooCommerce
/// version) never disables v4 for the rest of the session.
///
@MainActor
final class V4RefundAvailabilityCache {

    /// App-session-shared instance. Site-keyed, so it is safe to keep for the whole session.
    static let shared = V4RefundAvailabilityCache()

    private var availabilityBySiteID: [Int64: Bool] = [:]

    init() {}

    /// Returns `true`/`false` once determined, or `nil` if v4 availability hasn't been probed yet.
    func isV4Available(siteID: Int64) -> Bool? {
        guard siteID > 0 else {
            return nil
        }
        return availabilityBySiteID[siteID]
    }

    func markV4Available(siteID: Int64) {
        guard siteID > 0 else {
            return
        }
        availabilityBySiteID[siteID] = true
    }

    func markV4Unavailable(siteID: Int64) {
        guard siteID > 0 else {
            return
        }
        availabilityBySiteID[siteID] = false
    }
}
