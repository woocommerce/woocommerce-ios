import Foundation
@testable import WooCommerce


public class MockupAnalyticsProvider: AnalyticsProvider {
    var receivedEvents = [String]()
    var receivedProperties = [[AnyHashable : Any]]()
}


// MARK: - AnalyticsProvider Conformance
//
public extension MockupAnalyticsProvider {

    func beginSession() {}

    func track(_ eventName: String) {
        track(eventName, withProperties: nil)
    }

    func track(_ eventName: String, withProperties properties: [AnyHashable : Any]?) {
        receivedEvents.append(eventName)
        if let properties = properties {
            receivedProperties.append(properties)
        }
    }
}
