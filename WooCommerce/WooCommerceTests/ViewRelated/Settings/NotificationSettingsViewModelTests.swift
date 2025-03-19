import UserNotifications
import Testing
@testable import WooCommerce

struct NotificationSettingsViewModelTests {

    @Test(arguments: [
        UNAuthorizationStatus.notDetermined,
        UNAuthorizationStatus.denied,
        UNAuthorizationStatus.provisional,
        UNAuthorizationStatus.ephemeral
    ])
    func notificationsEnabled_is_false_notification_permission_is_not_authorized(authorizationStatus: UNAuthorizationStatus) async {
        // Given
        let notificationCenter = MockUserNotificationsCenterAdapter()
        notificationCenter.authorizationStatus = authorizationStatus
        let viewModel = NotificationSettingsViewModel(notificationCenter: notificationCenter)

        // When
        await viewModel.checkNotificationPermission()

        // Then
        #expect(viewModel.notificationsEnabled == false)
    }

    @Test func notificationsEnabled_is_true_notification_permission_is_authorized() async {
        // Given
        let notificationCenter = MockUserNotificationsCenterAdapter()
        notificationCenter.authorizationStatus = .authorized
        let viewModel = NotificationSettingsViewModel(notificationCenter: notificationCenter)

        // When
        await viewModel.checkNotificationPermission()

        // Then
        #expect(viewModel.notificationsEnabled == true)
    }
}
