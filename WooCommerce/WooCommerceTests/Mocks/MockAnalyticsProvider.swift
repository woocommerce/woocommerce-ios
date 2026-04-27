import Foundation
import protocol WooFoundation.AnalyticsProvider
@testable import WooCommerce
@testable import WordPressShared
import XCTest
import Testing

public class MockAnalyticsProvider: NSObject, AnalyticsProvider, WPAnalyticsTracker {
    private let lock = NSLock()

    private var _receivedEvents = [String]()
    var receivedEvents: [String] {
        lock.lock()
        defer { lock.unlock() }
        return _receivedEvents
    }

    private var _receivedProperties = [[AnyHashable: Any]]()
    var receivedProperties: [[AnyHashable: Any]] {
        lock.lock()
        defer { lock.unlock() }
        return _receivedProperties
    }

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
        lock.lock()
        _receivedEvents.append(eventName)
        if let properties {
            _receivedProperties.append(properties)
        }
        lock.unlock()
    }

    func clearEvents() {
        lock.lock()
        _receivedEvents.removeAll()
        _receivedProperties.removeAll()
        lock.unlock()
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
extension MockAnalyticsProvider {
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

// MARK: - Helper
extension MockAnalyticsProvider {
    /// Returns `true` if the event was tracked and the expected properties match.
    /// Useful for Swift Testing: `#expect(analyticsProvider.received(event: ..., with: ...))`.
    func received(event: String, with expectedProperties: [String: Any] = [:]) -> Bool {
        guard let index = receivedEvents.firstIndex(of: event) else {
            return false
        }

        guard index < receivedProperties.count else {
            return expectedProperties.isEmpty
        }

        let properties = receivedProperties[index]
        for (key, expectedValue) in expectedProperties {
            let actualValue = properties[key] as Any?
            if (actualValue as? NSObject) != (expectedValue as? NSObject) {
                return false
            }
        }

        return true
    }

    func properties(for event: String) -> [AnyHashable: Any]? {
        guard let index = receivedEvents.firstIndex(of: event) else {
            return nil
        }
        guard index < receivedProperties.count else {
            return nil
        }
        return receivedProperties[index]
    }

    func assertReceived(
        event: String,
        with expectedProperties: [String: Any] = [:],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let index = receivedEvents.firstIndex(of: event) else {
            XCTFail("Expected analytics event not received: \(event)", file: file, line: line)
            return
        }

        guard index < receivedProperties.count else {
            XCTFail("Expected analytics properties for event but none were recorded: \(event)", file: file, line: line)
            return
        }

        let properties = receivedProperties[index]
        for (key, expectedValue) in expectedProperties {
            let actualValue = properties[key] as Any?
            XCTAssertEqual(
                actualValue as? NSObject,
                expectedValue as? NSObject,
                "Mismatch for analytics property '\(key)' on event '\(event)'",
                file: file,
                line: line
            )
        }
    }
}
