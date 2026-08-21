import Foundation

/// Per-site, in-memory availability of the server-calculated refund endpoints
/// (`/wc/v3` preview and `compute_totals` create, WC 11.1.0+).
///
/// `markAvailable` must only be called after a successful preview, and `markUnavailable` only when
/// the preview route is missing (`rest_no_route`). The cache keeps a site with no preview route
/// from being probed again; an unknown site is not blocked. It does not authorise a computed
/// create on its own — that needs the version check in `POSRefundFlowResolver` and a preview for
/// the selection being submitted (`POSRefundSubmissionAdaptor`).
///
@MainActor
final class ServerRefundAvailabilityCache {

    static let shared = ServerRefundAvailabilityCache()

    private var availabilityBySiteID: [Int64: Bool] = [:]

    init() {}

    // The siteID > 0 guards are deliberate: 0 is the placeholder when no site is selected,
    // and a verdict recorded under it would answer for every session in that state.
    // Returning nil means unknown, which fails closed to the local flow.
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
