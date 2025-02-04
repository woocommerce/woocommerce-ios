import Foundation
import Yosemite
import AutomatticTracks
import WordPressShared
import protocol WooFoundation.AnalyticsProvider

public class TracksProvider: NSObject, AnalyticsProvider {
    private static let contextManager: TracksContextManager = TracksContextManager()

    private static let tracksService: TracksService = {
        let tracksService = TracksService(contextManager: contextManager)!
        tracksService.eventNamePrefix = Constants.eventNamePrefix
        return tracksService
    }()

    private static var isPOSModeActive: Bool = false

    public static func setPOSMode(_ active: Bool) {
        isPOSModeActive = active
    }
}


// MARK: - AnalyticsProvider Conformance
//
public extension TracksProvider {
    func refreshUserData() {
        switchTracksUsersIfNeeded()
        refreshTracksMetadata()
    }

    func track(_ eventName: String) {
        track(eventName, withProperties: nil)
    }

    func track(_ eventName: String, withProperties properties: [AnyHashable: Any]?) {
        let eventName = decorateEventNameForPOSIfNeeded(eventName)
        if let properties {
            guard Self.tracksService.trackEventName(eventName, withCustomProperties: properties) else {
                return DDLogError("🔴 Error tracking \(eventName) with properties: \(properties)")
            }

            let keyValuePairs = properties
                .map { key, value in
                    "\(key): \(value)"
                }
                .joined(separator: ", ")

            DDLogInfo("🔵 Tracked \(eventName), properties: [\(keyValuePairs)]")
        } else {
            Self.tracksService.trackEventName(eventName)
            DDLogInfo("🔵 Tracked \(eventName)")
        }
    }

    func clearEvents() {
        Self.tracksService.clearQueuedEvents()
    }

    /// When a user opts-out, wipe data
    ///
    func clearUsers() {
        guard ServiceLocator.analytics.userHasOptedIn else {
            // To be safe, nil out the anonymousUserID guid so a fresh one is regenerated
            UserDefaults.standard[.defaultAnonymousID] = nil
            UserDefaults.standard[.analyticsUsername] = nil
            Self.tracksService.switchToAnonymousUser(withAnonymousID: ServiceLocator.stores.sessionManager.anonymousUserID)
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
        let anonymousID = ServiceLocator.stores.sessionManager.anonymousUserID
        if ServiceLocator.stores.isAuthenticated,
           let account = ServiceLocator.stores.sessionManager.defaultAccount,
           case let .wpcom(_, authToken, _) = ServiceLocator.stores.sessionManager.defaultCredentials {
            if currentAnalyticsUsername.isEmpty {
                // No previous username logged
                UserDefaults.standard[.analyticsUsername] = account.username
                Self.tracksService.switchToAuthenticatedUser(withUsername: account.username,
                                                             userID: String(account.userID),
                                                             wpComToken: authToken,
                                                             skipAliasEventCreation: false)
            } else if currentAnalyticsUsername == account.username {
                // Username did not change - just make sure Tracks client has it
                Self.tracksService.switchToAuthenticatedUser(withUsername: account.username,
                                                             userID: String(account.userID),
                                                             wpComToken: authToken,
                                                             skipAliasEventCreation: true)
            } else {
                // Username changed for some reason - switch back to anonymous first
                Self.tracksService.switchToAnonymousUser(withAnonymousID: anonymousID)
                Self.tracksService.switchToAuthenticatedUser(withUsername: account.username,
                                                             userID: String(account.userID),
                                                             wpComToken: authToken,
                                                             skipAliasEventCreation: false)
            }
        } else {
            UserDefaults.standard[.analyticsUsername] = nil
            Self.tracksService.switchToAnonymousUser(withAnonymousID: anonymousID)
        }
    }

    private func decorateEventNameForPOSIfNeeded(_ eventName: String) -> String {
        // We do not want to track some events that might happen in POS mode as `pos_` events,
        // for example, when backgrounding the app or finishing async work from the app side.
        // Ref: https://github.com/woocommerce/woocommerce-ios/pull/15006#issuecomment-2622001706
        let exemptedEvents: Set<String> = [
            "application_opened",
            "application_closed",
            "support_new_request_viewed",
            "dynamic_dashboard_card_data_loading_completed"
        ]
        if exemptedEvents.contains(eventName) {
            return eventName
        }

        if Self.isPOSModeActive {
            let prefix = "pos_"
            return "\(prefix)\(eventName)"
        }
        return eventName
    }

    func refreshTracksMetadata() {
        DDLogInfo("♻️ Refreshing tracks metadata...")
        var userProperties = [String: Any]()
        userProperties[UserProperties.platformKey] = "iOS"
        userProperties[UserProperties.voiceOverKey] = UIAccessibility.isVoiceOverRunning
        userProperties[UserProperties.rtlKey] = (UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft)
        Self.tracksService.userProperties.removeAllObjects()
        Self.tracksService.userProperties.addEntries(from: userProperties)
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

extension TracksProvider: WPAnalyticsTracker {
    public func trackString(_ event: String?) {
        trackString(event, withProperties: nil)
    }

    public func trackString(_ event: String?, withProperties properties: [AnyHashable: Any]?) {
        guard let eventName = event else {
            DDLogInfo("🔴 Attempted to track an event without name.")
            return
        }

        track(eventName, withProperties: properties)
    }

    public func track(_ stat: WPAnalyticsStat) {
        // no op.
        track(stat, withProperties: nil)
    }

    public func track(_ stat: WPAnalyticsStat, withProperties properties: [AnyHashable: Any]?) {
        // no op
    }
}
