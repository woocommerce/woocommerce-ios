@testable import WooCommerce

final class MockBlazeLocalNotificationScheduler: BlazeLocalNotificationScheduler {
    private(set) var scheduleNotificationsCalled = false

    func scheduleNotifications() {
        scheduleNotificationsCalled = true
    }
}
