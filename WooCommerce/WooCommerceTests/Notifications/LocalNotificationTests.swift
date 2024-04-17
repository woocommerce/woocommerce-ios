import XCTest
@testable import WooCommerce

final class LocalNotificationTests: XCTestCase {

    func test_unknown_scenario_returns_correct_notification_contents() throws {
        // Given
        let scenario = LocalNotification.Scenario.unknown(siteID: 123)
        let notification = LocalNotification(scenario: scenario)

        // Then
        let expectedTitle = LocalNotification.Localization.unknown
        let expectedBody = LocalNotification.Localization.unknown
        assertEqual(expectedTitle, notification.title)
        assertEqual(expectedBody, notification.body)
        XCTAssertNil(notification.actions)
    }
}
