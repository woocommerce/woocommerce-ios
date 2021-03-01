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
