import XCTest
@testable import WooCommerce

final class LocalNotificationTests: XCTestCase {

    func test_storeCreationComplete_scenario_returns_correct_notification_contents() throws {
        // Given
        let scenario = LocalNotification.Scenario.storeCreationComplete(siteID: 123)
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

    func test_sixHoursAfterFreeTrialSubscribed_scenario_returns_correct_notification_contents() throws {
        // Given
        let scenario = LocalNotification.Scenario.sixHoursAfterFreeTrialSubscribed(siteID: 123)
        let notification = LocalNotification(scenario: scenario)

        // Then
        let expectedTitle = LocalNotification.Localization.SixHoursAfterFreeTrialSubscribed.title
        let expectedBody = LocalNotification.Localization.SixHoursAfterFreeTrialSubscribed.body
        assertEqual(expectedTitle, notification.title)
        assertEqual(expectedBody, notification.body)
        XCTAssertNil(notification.actions)
    }

    func test_freeTrialSurvey24hAfterFreeTrialSubscribed_scenario_returns_correct_notification_contents() throws {
        // Given
        let scenario = LocalNotification.Scenario.freeTrialSurvey24hAfterFreeTrialSubscribed(siteID: 123)
        let notification = LocalNotification(scenario: scenario)

        // Then
        let expectedTitle = LocalNotification.Localization.FreeTrialSurvey24hAfterFreeTrialSubscribed.title
        let expectedBody = LocalNotification.Localization.FreeTrialSurvey24hAfterFreeTrialSubscribed.body
        assertEqual(expectedTitle, notification.title)
        assertEqual(expectedBody, notification.body)
        XCTAssertNil(notification.actions)
    }

    func test_threeDaysAfterStillExploring_scenario_returns_correct_notification_contents() throws {
        // Given
        let scenario = LocalNotification.Scenario.threeDaysAfterStillExploring(siteID: 123)
        let notification = LocalNotification(scenario: scenario)

        // Then
        let expectedTitle = LocalNotification.Localization.ThreeDaysAfterStillExploring.title
        let expectedBody = LocalNotification.Localization.ThreeDaysAfterStillExploring.body
        assertEqual(expectedTitle, notification.title)
        assertEqual(expectedBody, notification.body)
        XCTAssertNil(notification.actions)
    }
}
