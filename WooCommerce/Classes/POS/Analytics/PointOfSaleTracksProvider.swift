import Foundation
import AutomatticTracks
import protocol WooFoundation.AnalyticsProvider

public class PointOfSaleTracksProvider: NSObject, AnalyticsProvider {
    private static let contextManager: TracksContextManager = TracksContextManager()
    
    private static let tracksService: TracksService = {
        let tracksService = TracksService(contextManager: contextManager)!
        tracksService.eventNamePrefix = "woocommerceios_pos"
        return tracksService
    }()
}

public extension PointOfSaleTracksProvider {
    func refreshUserData() {
        // Not implemented
    }

    func track(_ eventName: String) {
        track(eventName, withProperties: nil)
    }

    func track(_ eventName: String, withProperties properties: [AnyHashable: Any]?) {
        // Properties not implemented
        Self.tracksService.trackEventName(eventName)
        DDLogInfo("🔵 Tracked \(eventName)")
    }

    func clearEvents() {
        // Not implemented
    }

    func clearUsers() {
        // Not implemented
    }
}
