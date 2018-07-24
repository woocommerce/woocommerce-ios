import Foundation
import AutomatticTracks
import CocoaLumberjack


public class TracksProvider: AnalyticsProvider {

    private var contextManager: TracksContextManager
    private var tracksService: TracksService

    /// Designated Initializer
    ///
    init() {
        self.contextManager = TracksContextManager()
        self.tracksService  = TracksService.init(contextManager: contextManager)
    }
}


// MARK: - AnalyticsProvider Conformance
//
public extension TracksProvider {

    func track(_ eventName: String) {
        track(eventName, withProperties: nil)
    }

    func track(_ eventName: String, withProperties properties: [AnyHashable : Any]?) {
        if let properties = properties {
            tracksService.trackEventName(eventName, withCustomProperties: properties)
            DDLogInfo("🔵 Tracked \(eventName), properties: \(properties)")
        } else {
            tracksService.trackEventName(eventName)
            DDLogInfo("🔵 Tracked \(eventName)")
        }
    }
}
