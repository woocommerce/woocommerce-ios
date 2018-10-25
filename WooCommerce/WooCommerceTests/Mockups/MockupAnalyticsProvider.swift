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
public extension MockupAnalyticsProvider {

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

    func clearTracksEvents() {
        receivedEvents.removeAll()
    }

    func clearTracksUsers() {
        userOptedIn = false
        userID = nil
    }
}
