import Foundation
import WatchConnectivity

/// Delegate track events to the paired counterpart using the `WCSession`
///
final class WatchTracksProvider: NSObject, ObservableObject {

    /// Store events that could not be sent when the because was not active
    ///
    private var queuedEvents: [WooAnalyticsStat] = []

    /// Tries to resend queued events.
    /// Call this method when the `WCSession` is activated.
    ///
    func flushQueuedEvents() {
        let eventsToFlush = queuedEvents
        queuedEvents.removeAll()

        for eventToFlush in eventsToFlush {
            sendTracksEvent(eventToFlush)
        }
    }

    /// Send the event to the paired device.
    /// Discussion: This method uses the `transferUserInfo` to guarantee it's delivery to the paired counterpart. When testing use real device.
    ///
    func sendTracksEvent(_ event: WooAnalyticsStat) {
        guard WCSession.default.activationState == .activated else {
            DDLogInfo("🔵 Track event queued: \(event.rawValue)")
            queuedEvents.append(event)
            return
        }

        WCSession.default.transferUserInfo([WooConstants.watchTracksKey: "\(event.rawValue)"])
        DDLogInfo("🔵 Track event delegated: \(event.rawValue)")
    }
}
