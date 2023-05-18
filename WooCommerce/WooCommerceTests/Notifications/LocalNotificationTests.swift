import XCTest
@testable import WooCommerce

final class LocalNotificationTests: XCTestCase {

    func test_storeCreationComplete_scenario_returns_correct_notification_contents() throws {
        // Given
        let scenario = LocalNotification.Scenario.storeCreationComplete
        let testName = "Miffy"
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, displayName: testName))

        // When
        let notification = LocalNotification(scenario: scenario, stores: stores)

        // Then
        assertEqual(LocalNotification.Localization.StoreCreationComplete.title, notification.title)
        XCTAssertNil(notification.actions)
        let expectedBody = String.localizedStringWithFormat(LocalNotification.Localization.StoreCreationComplete.body, testName)
        assertEqual(expectedBody, notification.body)
    }

    func test_oneDayAfterStoreCreationNameWithoutFreeTrial_scenario_returns_correct_notification_contents() throws {
        // Given
        let storeName = "BunnyLand"
        let scenario = LocalNotification.Scenario.oneDayAfterStoreCreationNameWithoutFreeTrial(storeName: storeName)
        let testName = "Miffy"
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, displayName: testName))

        // When
        let notification = LocalNotification(scenario: scenario, stores: stores)

        // Then
        assertEqual(LocalNotification.Localization.OneDayAfterStoreCreationNameWithoutFreeTrial.title, notification.title)
        XCTAssertNil(notification.actions)
        let expectedBody = String.localizedStringWithFormat(
            LocalNotification.Localization.OneDayAfterStoreCreationNameWithoutFreeTrial.body,
            testName,
            storeName
        )
        assertEqual(expectedBody, notification.body)
    }

    func test_oneDayBeforeFreeTrialExpires_scenario_returns_correct_notification_contents() throws {
        // Given
        let date = Date(timeIntervalSince1970: 1683692966) // GMT: Wed, 10 May
        let timeZone = try XCTUnwrap(TimeZone(identifier: "GMT"))
        let locale = Locale(identifier: "en-US")
        let scenario = LocalNotification.Scenario.oneDayBeforeFreeTrialExpires(siteID: 123, expiryDate: date)
        let testName = "Miffy"
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, displayName: testName))

        // When
        let notification = LocalNotification(scenario: scenario, stores: stores, timeZone: timeZone, locale: locale)

        // Then
        let expectedTitle = LocalNotification.Localization.OneDayBeforeFreeTrialExpires.title
        let expectedBody = String.localizedStringWithFormat(LocalNotification.Localization.OneDayBeforeFreeTrialExpires.body, "Wednesday, May 10")
        assertEqual(expectedTitle, notification.title)
        assertEqual(expectedBody, notification.body)
        XCTAssertNil(notification.actions)
    }

    func test_oneDayAfterFreeTrialExpires_scenario_returns_correct_notification_contents() throws {
        // Given
        let scenario = LocalNotification.Scenario.oneDayAfterFreeTrialExpires(siteID: 123)
        let testName = "Miffy"
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, displayName: testName))

        // When
        let notification = LocalNotification(scenario: scenario, stores: stores)

        // Then
        let expectedTitle = LocalNotification.Localization.OneDayAfterFreeTrialExpires.title
        let expectedBody = String.localizedStringWithFormat(LocalNotification.Localization.OneDayAfterFreeTrialExpires.body, testName)
        assertEqual(expectedTitle, notification.title)
        assertEqual(expectedBody, notification.body)
        XCTAssertNil(notification.actions)
    }
}
