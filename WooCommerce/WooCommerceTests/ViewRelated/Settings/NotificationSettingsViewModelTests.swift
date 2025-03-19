import Combine
import UIKit
import UserNotifications
import XCTest
@testable import WooCommerce

final class NotificationSettingsViewModelTests: XCTestCase {

    private var subscription: AnyCancellable?

    func test_notificationsEnabled_is_false_notification_permission_is_not_authorized() async {
        // Given
        let notificationCenter = MockUserNotificationsCenterAdapter()
        let statuses = [
            UNAuthorizationStatus.notDetermined,
            UNAuthorizationStatus.denied,
            UNAuthorizationStatus.provisional,
            UNAuthorizationStatus.ephemeral
        ]

        for status in statuses {
            // When
            notificationCenter.authorizationStatus = status
            let viewModel = NotificationSettingsViewModel(notificationCenter: notificationCenter)

            let expectation = XCTestExpectation(description: "Notification authorization status updated")
            subscription = viewModel.$notificationsEnabled
                .dropFirst()
                .sink { _ in
                    expectation.fulfill()
                }

            await fulfillment(of: [expectation])

            // Then
            XCTAssertFalse(viewModel.notificationsEnabled)
        }
    }

    func test_notificationsEnabled_is_true_notification_permission_is_authorized() async {
        // Given
        let notificationCenter = MockUserNotificationsCenterAdapter()
        notificationCenter.authorizationStatus = .authorized

        // When
        let viewModel = NotificationSettingsViewModel(notificationCenter: notificationCenter)
        let expectation = XCTestExpectation(description: "Notification authorization status updated")
        subscription = viewModel.$notificationsEnabled
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }

        await fulfillment(of: [expectation])

        // Then
        XCTAssertTrue(viewModel.notificationsEnabled)
    }

    func test_notificationEnabled_is_updated_when_app_becomes_active() async {
        // Given
        let notificationCenter = MockUserNotificationsCenterAdapter()
        notificationCenter.authorizationStatus = .denied

        let viewModel = NotificationSettingsViewModel(notificationCenter: notificationCenter)
        var notificationStatuses: [Bool] = []
        let expectation = XCTestExpectation(description: "Notification authorization status updated")
        subscription = viewModel.$notificationsEnabled
            .dropFirst()
            .sink { status in
                notificationStatuses.append(status)
                if notificationStatuses.count == 2 {
                    expectation.fulfill()
                }
            }

        // When
        notificationCenter.authorizationStatus = .authorized
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        await fulfillment(of: [expectation])

        // Then
        XCTAssertEqual(notificationStatuses, [false, true])
    }
}
