@testable import WooCommerce

final class MockBlazeLocalNotificationScheduler: BlazeLocalNotificationScheduler {
    private(set) var observeNotificationUserResponseCalled = false
    private(set) var scheduleNoCampaignReminderCalled = false
    private(set) var scheduleAbandonedCreationReminderCalled = false

    func observeNotificationUserResponse() {
        observeNotificationUserResponseCalled = true
    }

    func scheduleNoCampaignReminder() async {
        scheduleNoCampaignReminderCalled = true
    }

    func scheduleAbandonedCreationReminder() async {
        scheduleAbandonedCreationReminderCalled = true
    }

    func cancelAbandonedCreationReminder() async {

    }
}
