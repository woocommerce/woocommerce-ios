import Foundation

@testable import WooCommerce

public class MockupAnalyticsProvider: AnalyticsProvider {
    var receivedEvents = [String]()
    var receivedProperties = [[AnyHashable: Any]]()
    var userID: String?
    var userOptedIn = true
}


// MARK: - AnalyticsProvider Conformance
//
extension MockupAnalyticsProvider {

    public func refreshUserData() {
        userID = "aGeneratedUserGUID"
    }

    public func track(_ eventName: String) {
        track(eventName, withProperties: nil)
    }

    public func track(_ eventName: String, withProperties properties: [AnyHashable: Any]?) {
        receivedEvents.append(eventName)
        if let properties = properties {
            receivedProperties.append(properties)
        }
    }

    public func clearEvents() {
        receivedEvents.removeAll()
    }

    public func clearUsers() {
        userOptedIn = false
        userID = nil
    }
}
