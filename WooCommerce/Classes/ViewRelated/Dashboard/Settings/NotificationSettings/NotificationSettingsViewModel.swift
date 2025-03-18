import Foundation

/// View model for `NotificationSettingsView`
final class NotificationSettingsViewModel: ObservableObject {
    @Published var notificationsEnabled = false
    @Published var orderNotificationsEnabled = false
    @Published var productReviewNotificationsEnabled = false
}
