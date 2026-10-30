import Foundation
import protocol WooFoundation.AnalyticsProvider
@testable import WooCommerce
@testable import WordPressShared
import XCTest
import Testing
import os

public final class MockAnalyticsProvider: NSObject, AnalyticsProvider, WPAnalyticsTracker {
    private struct State {
        var receivedEvents = [String]()
        var receivedProperties = [[AnyHashable: Any]]()
        var userID: String?
        var userOptedIn = true
        var defersRefreshUserDataCompletion = false
        var refreshUserDataCallCount = 0
        var refreshUserDataCompletion: (@Sendable () -> Void)?
    }

    private let state = OSAllocatedUnfairLock(uncheckedState: State())

    var receivedEvents: [String] {
        state.withLockUnchecked { $0.receivedEvents }
    }

    var receivedProperties: [[AnyHashable: Any]] {
        state.withLockUnchecked { $0.receivedProperties }
    }

    var userID: String? {
        get { state.withLockUnchecked { $0.userID } }
        set { state.withLockUnchecked { $0.userID = newValue } }
    }

    var userOptedIn: Bool {
        get { state.withLockUnchecked { $0.userOptedIn } }
        set { state.withLockUnchecked { $0.userOptedIn = newValue } }
    }

    var defersRefreshUserDataCompletion: Bool {
        get { state.withLockUnchecked { $0.defersRefreshUserDataCompletion } }
        set { state.withLockUnchecked { $0.defersRefreshUserDataCompletion = newValue } }
    }

    private(set) var refreshUserDataCallCount: Int {
        get { state.withLockUnchecked { $0.refreshUserDataCallCount } }
        set { state.withLockUnchecked { $0.refreshUserDataCallCount = newValue } }
    }
}

// MARK: - AnalyticsProvider Conformance
//
public extension MockAnalyticsProvider {

    func refreshUserData(completion: @escaping @Sendable () -> Void) {
        let completionToCall: (@Sendable () -> Void)? = state.withLockUnchecked { state in
            state.refreshUserDataCallCount += 1
            state.userID = "aGeneratedUserGUID"
            if state.defersRefreshUserDataCompletion {
                state.refreshUserDataCompletion = completion
                return nil
            }
            return completion
        }
        completionToCall?()
    }

    func completeRefreshUserData() {
        let completion = state.withLockUnchecked { state in
            let completion = state.refreshUserDataCompletion
            state.refreshUserDataCompletion = nil
            return completion
        }
        completion?()
    }

    func track(_ eventName: String) {
        track(eventName, withProperties: nil)
    }

    func track(_ eventName: String, withProperties properties: [AnyHashable: Any]?) {
        state.withLockUnchecked { state in
            state.receivedEvents.append(eventName)
            if let properties {
                state.receivedProperties.append(properties)
            }
        }
    }

    func clearEvents() {
        state.withLockUnchecked {
            $0.receivedEvents.removeAll()
            $0.receivedProperties.removeAll()
        }
    }

    func clearUsers() {
        state.withLockUnchecked {
            $0.userOptedIn = false
            $0.userID = nil
        }
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
