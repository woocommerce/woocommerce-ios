import Foundation
import Yosemite
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
    func beginSession() {
        if StoresManager.shared.isAuthenticated, let accountID = StoresManager.shared.sessionManager.defaultAccountID {
            tracksService.switchToAuthenticatedUser(withUsername: String(accountID), userID: nil, skipAliasEventCreation: true)
        } else {
            tracksService.switchToAnonymousUser(withAnonymousID: StoresManager.shared.sessionManager.anonymousUserID)
        }
        refreshMetadata()
    }

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


// MARK: - Private Helpers
//
private extension TracksProvider {
    func refreshMetadata() {
        var userProperties = [String: Any]()
        userProperties["platform"] = "iOS";
        userProperties["accessibility_voice_over_enabled"] = UIAccessibilityIsVoiceOverRunning()
        userProperties["is_rtl_language"] = (UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft)
        tracksService.userProperties.removeAllObjects()
        tracksService.userProperties.addEntries(from: userProperties)
    }
}
