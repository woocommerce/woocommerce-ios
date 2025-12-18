import Foundation
import UserNotifications
import Yosemite

protocol MarketingEventNotificationScheduling {
    func scheduleNotification(for event: MarketingEvent, daysBeforeEvent: Int) async
    func cancelNotification(for event: MarketingEvent) async
}

final class MarketingEventNotificationScheduler: MarketingEventNotificationScheduling {
    private let pushNotificationsManager: PushNotesManager

    init(pushNotificationsManager: PushNotesManager = ServiceLocator.pushNotesManager) {
        self.pushNotificationsManager = pushNotificationsManager
    }

    /// Schedules a local notification for a marketing event
    /// - Parameters:
    ///   - event: The marketing event to schedule a reminder for
    ///   - daysBeforeEvent: Number of days before the event to send the notification (default: 3)
    func scheduleNotification(for event: MarketingEvent, daysBeforeEvent: Int = 3) async {
        // TODO: Check notification authorization status before scheduling
        // TODO: Request authorization if needed (ensureAuthorizationIsRequested)

        // Calculate notification time (X days before event)
        guard let notificationDate = Calendar.current.date(
            byAdding: .day,
            value: -daysBeforeEvent,
            to: event.date
        ) else {
            return
        }

        // Don't schedule if notification time has passed
        guard notificationDate > Date.now else {
            return
        }

        // Check if already scheduled to avoid duplicates
        let isAlreadyScheduled = await isNotificationScheduled(for: event)
        guard !isAlreadyScheduled else {
            return
        }

        // Create notification with event data in userInfo
        let notification = LocalNotification(
            scenario: .marketingEventReminder,
            userInfo: [
                LocalNotification.UserInfoKey.eventID: event.id,
                LocalNotification.UserInfoKey.eventName: event.name
            ]
        )

        // Create calendar trigger for the notification time
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: notificationDate
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        // Schedule the notification
        await pushNotificationsManager.requestLocalNotification(notification, trigger: trigger)
    }

    /// Cancels a scheduled notification for a marketing event
    /// - Parameter event: The marketing event whose notification should be canceled
    func cancelNotification(for event: MarketingEvent) async {
        await pushNotificationsManager.cancelLocalNotification(scenarios: [.marketingEventReminder])
    }

    /// Checks if a notification is already scheduled for the given event
    /// - Parameter event: The marketing event to check
    /// - Returns: True if a notification is already scheduled, false otherwise
    private func isNotificationScheduled(for event: MarketingEvent) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()

        // Check if any pending notification matches this event ID
        return pendingRequests.contains { request in
            request.identifier == LocalNotification.Scenario.marketingEventReminder.identifier &&
            request.content.userInfo[LocalNotification.UserInfoKey.eventID] as? String == event.id
        }
    }
}
