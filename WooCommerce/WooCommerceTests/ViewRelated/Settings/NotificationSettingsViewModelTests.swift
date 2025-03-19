import UIKit
import UserNotifications
import Testing
@testable import WooCommerce

struct NotificationSettingsViewModelTests {

    @Test("Notification authorization statuses", arguments: [
        UNAuthorizationStatus.notDetermined,
        UNAuthorizationStatus.denied,
        UNAuthorizationStatus.provisional,
        UNAuthorizationStatus.ephemeral
    ])
    func notificationsEnabled_is_false_notification_permission_is_not_authorized(authorizationStatus: UNAuthorizationStatus) async throws {
        // Given
        let notificationCenter = MockUserNotificationsCenterAdapter()
        notificationCenter.authorizationStatus = authorizationStatus

        // When
        let viewModel = NotificationSettingsViewModel(notificationCenter: notificationCenter)
        // bad workaround to wait for async update of `notificationsEnabled`
        try await Task.sleep(nanoseconds: 300)

        // Then
        #expect(viewModel.notificationsEnabled == false)
    }

    @Test func notificationsEnabled_is_true_notification_permission_is_authorized() async throws {
        // Given
        let notificationCenter = MockUserNotificationsCenterAdapter()
        notificationCenter.authorizationStatus = .authorized

        // When
        let viewModel = NotificationSettingsViewModel(notificationCenter: notificationCenter)
        // bad workaround to wait for async update of `notificationsEnabled`
        try await Task.sleep(nanoseconds: 300)

        // Then
        #expect(viewModel.notificationsEnabled == true)
    }

    @Test func notificationEnabled_is_updated_when_app_becomes_active() async throws {
        // Given
        let notificationCenter = MockUserNotificationsCenterAdapter()
        notificationCenter.authorizationStatus = .denied

        let viewModel = NotificationSettingsViewModel(notificationCenter: notificationCenter)
        // Confidence check
        #expect(viewModel.notificationsEnabled == false)

        // When
        notificationCenter.authorizationStatus = .authorized
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        // bad workaround to wait for async update of `notificationsEnabled`
        try await Task.sleep(nanoseconds: 300)

        // Then
        #expect(viewModel.notificationsEnabled == true)
    }
}
