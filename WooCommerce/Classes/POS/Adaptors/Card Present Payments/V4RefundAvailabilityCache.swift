import Foundation

@MainActor
final class V4RefundAvailabilityCache {

    static let shared = V4RefundAvailabilityCache()

    private var availabilityBySiteID: [Int64: Bool] = [:]

    init() {}

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
