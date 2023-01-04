import Foundation
import AutomatticTracks
import WordPressShared

public class TracksProvider: NSObject {
    public static var shared: TracksProvider = {
        TracksProvider()
    }()

    lazy private var contextManager: TracksContextManager = {
        return TracksContextManager()
    }()

    lazy private var tracksService: TracksService = {
        let tracksService = TracksService(contextManager: contextManager)!
        tracksService.eventNamePrefix = Constants.eventNamePrefix

        var userProperties = [String: Any]()
        userProperties[UserProperties.platformKey] = "iOS"
        tracksService.userProperties.removeAllObjects()
        tracksService.userProperties.addEntries(from: userProperties)

        return tracksService
    }()

    func track(_ eventName: String, withProperties properties: [AnyHashable: Any]? = nil) {
        if let properties = properties {
            tracksService.trackEventName(eventName, withCustomProperties: properties)
            DDLogInfo("🔵 Tracked \(eventName), properties: \(properties)")
        } else {
            tracksService.trackEventName(eventName)
            DDLogInfo("🔵 Tracked \(eventName)")
        }
    }
}


private extension TracksProvider {
    enum Constants {
        static let eventNamePrefix = "woocommerceios"
    }

    enum UserProperties {
        static let platformKey          = "platform"
        static let voiceOverKey         = "accessibility_voice_over_enabled"
        static let rtlKey               = "is_rtl_language"
    }
}
