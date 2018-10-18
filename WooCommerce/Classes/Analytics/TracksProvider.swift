import Foundation
import Yosemite
import AutomatticTracks
import CocoaLumberjack


public class TracksProvider: AnalyticsProvider {

    private let contextManager: TracksContextManager
    private let tracksService: TracksService


    /// Designated Initializer
    ///
    init() {
        self.contextManager = TracksContextManager()
        self.tracksService = TracksService(contextManager: contextManager)
        self.tracksService.eventNamePrefix = Constants.eventNamePrefix
    }
}


// MARK: - AnalyticsProvider Conformance
//
public extension TracksProvider {
    func refreshUserData() {
        if StoresManager.shared.isAuthenticated, let account = StoresManager.shared.sessionManager.defaultAccount {
            tracksService.switchToAuthenticatedUser(withUsername: account.username, userID: String(account.userID), skipAliasEventCreation: true)
        } else {
            tracksService.switchToAnonymousUser(withAnonymousID: StoresManager.shared.sessionManager.anonymousUserID)
        }
        refreshMetadata()
    }

    func track(_ eventName: String) {
        track(eventName, withProperties: nil)
    }

    func track(_ eventName: String, withProperties properties: [AnyHashable: Any]?) {
        if let properties = properties {
            tracksService.trackEventName(eventName, withCustomProperties: properties)
            DDLogInfo("🔵 Tracked \(eventName), properties: \(properties)")
        } else {
            tracksService.trackEventName(eventName)
            DDLogInfo("🔵 Tracked \(eventName)")
        }
    }

    func clearTracksEvents() {
        tracksService.clearQueuedEvents()
    }
}


// MARK: - Private Helpers
//
private extension TracksProvider {
    func refreshMetadata() {
        DDLogInfo("♻️ Refreshing tracks metadata...")
        var userProperties = [String: Any]()
        userProperties[UserProperties.platformKey] = "iOS"
        userProperties[UserProperties.voiceOverKey] = UIAccessibility.isVoiceOverRunning
        userProperties[UserProperties.rtlKey] = (UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft)
        if StoresManager.shared.isAuthenticated {
            let site = StoresManager.shared.sessionManager.defaultSite
            userProperties[UserProperties.blogIDKey] = site?.siteID
            userProperties[UserProperties.wpcomStoreKey] = site?.isWordPressStore
        }
        tracksService.userProperties.removeAllObjects()
        tracksService.userProperties.addEntries(from: userProperties)
    }
}


// MARK: - Constants!
//
private extension TracksProvider {

    enum Constants {
        static let eventNamePrefix = "woocommerceios"
    }

    enum UserProperties {
        static let platformKey          = "platform"
        static let voiceOverKey         = "accessibility_voice_over_enabled"
        static let rtlKey               = "is_rtl_language"
        static let blogIDKey            = "blog_id"
        static let wpcomStoreKey        = "is_wpcom_store"
    }
}
