import Testing
import UserNotifications
@testable import WooCommerce

struct NotificationSettingsViewModelTests {

    @Test("Notification authorization statuses", arguments: [
        UNAuthorizationStatus.notDetermined,
        UNAuthorizationStatus.denied,
        UNAuthorizationStatus.provisional,
        UNAuthorizationStatus.ephemeral
    ])
    func notificationsEnabled_is_false_notification_permission_is_not_authorized(authorizationStatus: UNAuthorizationStatus) {
        // Given
        let notificationCenter = MockUserNotificationsCenterAdapter()
        notificationCenter.authorizationStatus = authorizationStatus

        // When
        let viewModel = NotificationSettingsViewModel(notificationCenter: notificationCenter)

        // Then
        #expect(viewModel.notificationsEnabled == false)
    }

    func notificationsEnabled_is_true_notification_permission_is_authorized() {
        // Given
        let notificationCenter = MockUserNotificationsCenterAdapter()
        notificationCenter.authorizationStatus = .authorized

        // When
        let viewModel = NotificationSettingsViewModel(notificationCenter: notificationCenter)

        // Then
        #expect(viewModel.notificationsEnabled == true)
    }
}
