import Foundation

/// Per-site, in-memory availability of the server-calculated refund endpoints
/// (`/wc/v3` preview and `compute_totals` create, WC 11.1.0+).
///
/// `markAvailable` must only be called after a successful preview: on stores older than 11.1.0
/// the unknown `compute_totals` parameter is silently dropped by the classic create, so a
/// computed create must never be sent unless a preview has confirmed support for the site.
///
@MainActor
final class ServerRefundAvailabilityCache {

    static let shared = ServerRefundAvailabilityCache()

    private var availabilityBySiteID: [Int64: Bool] = [:]

    init() {}

    func isAvailable(siteID: Int64) -> Bool? {
        guard siteID > 0 else {
            return nil
        }
        return availabilityBySiteID[siteID]
    }

    func markAvailable(siteID: Int64) {
        guard siteID > 0 else {
            return
        }
        availabilityBySiteID[siteID] = true
    }

    func markUnavailable(siteID: Int64) {
        guard siteID > 0 else {
            return
        }
        availabilityBySiteID[siteID] = false
    }
}
