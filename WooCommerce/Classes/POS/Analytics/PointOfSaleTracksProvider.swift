import Foundation
import AutomatticTracks
import protocol WooFoundation.AnalyticsProvider

public class PointOfSaleTracksProvider: NSObject, AnalyticsProvider {
    private static let contextManager: TracksContextManager = TracksContextManager()

    private static let tracksService: TracksService = {
        guard let tracksService = TracksService(contextManager: contextManager) else {
            fatalError("Failed to create TracksService instance", file: #file, line: #line)
        }
        tracksService.eventNamePrefix = "woocommerceios_pos"
        return tracksService
    }()
}

public extension PointOfSaleTracksProvider {
    func refreshUserData() {
        // Not implemented.
        // We need to track merchant switches between opted in and opted out as anonymous users
        // also other metadata based on specific stores might be necessary
    }

    func track(_ eventName: String) {
        track(eventName, withProperties: nil)
    }

    func track(_ eventName: String, withProperties properties: [AnyHashable: Any]?) {
        // TODO: Properties not implemented
        Self.tracksService.trackEventName(eventName)
        DDLogInfo("🔵 Tracked \(eventName)")
    }

    func clearEvents() {
        Self.tracksService.clearQueuedEvents()
    }

    func clearUsers() {
        // TODO: Not implemented
    }
}
