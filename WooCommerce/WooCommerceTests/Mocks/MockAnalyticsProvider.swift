import Foundation
@testable import WooCommerce

public class MockAnalyticsProvider: AnalyticsProvider {
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
