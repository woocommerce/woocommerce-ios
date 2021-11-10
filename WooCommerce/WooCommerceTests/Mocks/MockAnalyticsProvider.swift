import Foundation
@testable import WooCommerce
@testable import WordPressShared

public class MockAnalyticsProvider: NSObject, AnalyticsProvider, WPAnalyticsTracker {
    var receivedEvents = [String]()
    var receivedProperties = [[AnyHashable: Any]]()
    var userID: String?
    var userOptedIn = true
}

// MARK: - AnalyticsProvider Conformance
//
public extension MockAnalyticsProvider {

    func refreshUserData() {
        userID = "aGeneratedUserGUID"
    }

    func track(_ eventName: String) {
        track(eventName, withProperties: nil)
    }

    func track(_ eventName: String, withProperties properties: [AnyHashable: Any]?) {
        receivedEvents.append(eventName)
        if let properties = properties {
            receivedProperties.append(properties)
        }
    }

    func clearEvents() {
        receivedEvents.removeAll()
    }

    func clearUsers() {
        userOptedIn = false
        userID = nil
    }
}


// MARK: - WPAnalyticsTracker Conformance
//

public extension MockAnalyticsProvider {
    func trackString(_ event: String?) {
        trackString(event, withProperties: nil)
    }

    func trackString(_ event: String?, withProperties properties: [AnyHashable: Any]?) {
        guard let eventName = event else {
            return
        }

        track(eventName, withProperties: properties)
    }

    func track(_ stat: WPAnalyticsStat) {
        // no op
    }

    func track(_ stat: WPAnalyticsStat, withProperties properties: [AnyHashable: Any]?) {
        // no op
    }
}

// MARK: - Convenience Keys
public extension MockAnalyticsProvider {
    /// WooAnalyticsKeys
    /// Canonically defined in WooAnalytics.swift
    enum WooAnalyticsKeys {
        static let errorKeyCode = "error_code"
        static let errorKeyDomain = "error_domain"
        static let errorKeyDescription = "error_description"
        static let propertyKeyTimeInApp = "time_in_app"
        static let blogIDKey = "blog_id"
        static let wpcomStoreKey = "is_wpcom_store"
    }
}
