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
        switchTracksUsersIfNeeded()
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

    func clearEvents() {
        tracksService.clearQueuedEvents()
    }

    /// When a user opts-out, wipe data
    ///
    func clearUsers() {
        guard WooAnalytics.shared.userHasOptedIn else {
            // To be safe, nil out the anonymousUserID guid so a fresh one is regenerated
            UserDefaults.standard[.defaultAnonymousID] = nil
            UserDefaults.standard[.analyticsUsername] = nil
            tracksService.switchToAnonymousUser(withAnonymousID: StoresManager.shared.sessionManager.anonymousUserID)
            return
        }

        switchTracksUsersIfNeeded()
    }
}


// MARK: - Private Helpers
//
private extension TracksProvider {
    func switchTracksUsersIfNeeded() {
        let currentAnalyticsUsername = UserDefaults.standard[.analyticsUsername] as? String ?? ""
        if StoresManager.shared.isAuthenticated, let account = StoresManager.shared.sessionManager.defaultAccount {
            if currentAnalyticsUsername.isEmpty {
                // No previous username logged
                UserDefaults.standard[.analyticsUsername] = account.username
                tracksService.switchToAuthenticatedUser(withUsername: account.username, userID: String(account.userID), skipAliasEventCreation: false)
            } else if currentAnalyticsUsername == account.username {
                // Username did not change - just make sure Tracks client has it
                tracksService.switchToAuthenticatedUser(withUsername: account.username, userID: String(account.userID), skipAliasEventCreation: true)
            } else {
                // Username changed for some reason - switch back to anonymous first
                tracksService.switchToAnonymousUser(withAnonymousID: StoresManager.shared.sessionManager.anonymousUserID)
                tracksService.switchToAuthenticatedUser(withUsername: account.username, userID: String(account.userID), skipAliasEventCreation: false)
            }
        } else {
            UserDefaults.standard[.analyticsUsername] = nil
            tracksService.switchToAnonymousUser(withAnonymousID: StoresManager.shared.sessionManager.anonymousUserID)
        }
    }

    func refreshMetadata() {
        DDLogInfo("♻️ Refreshing tracks metadata...")
        var userProperties = [String: Any]()
        userProperties[UserProperties.platformKey] = "iOS"
        userProperties[UserProperties.voiceOverKey] = UIAccessibility.isVoiceOverRunning
        userProperties[UserProperties.rtlKey] = (UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft)
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
    }
}
