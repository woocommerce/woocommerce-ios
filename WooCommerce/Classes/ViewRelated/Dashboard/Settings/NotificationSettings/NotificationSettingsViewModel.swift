import UIKit

/// View model for `NotificationSettingsView`
final class NotificationSettingsViewModel: ObservableObject {
    @Published private(set) var notificationsEnabled = false
    @Published var orderNotificationsEnabled = false
    @Published var productReviewNotificationsEnabled = false

    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter

        Task {
            await updateNotificationPermission()
        }
    }

    @MainActor
    func requestNotificationPermission() async {
        do {
            let isGranted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            notificationsEnabled = isGranted
        } catch {
            DDLogError("⛔️ Error requesting notification permission: \(error)")
        }
    }
}

private extension NotificationSettingsViewModel {
    @MainActor
    func updateNotificationPermission() async {
        let isEnabled = await withCheckedContinuation { continuation in
            notificationCenter.getNotificationSettings { settings in
                switch settings.authorizationStatus {
                case .authorized:
                    continuation.resume(returning: true)
                case .denied, .notDetermined, .provisional, .ephemeral:
                    continuation.resume(returning: false)
                @unknown default:
                    continuation.resume(returning: false)
                }
            }
        }
        notificationsEnabled = isEnabled
    }
}
