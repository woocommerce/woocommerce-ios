import UIKit

/// View model for `NotificationSettingsView`
final class NotificationSettingsViewModel: ObservableObject {
    @Published private(set) var notificationsEnabled = false
    @Published var orderNotificationsEnabled = false
    @Published var productReviewNotificationsEnabled = false

    private let notificationCenter: UNUserNotificationCenter

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter

        observeAppState()
        Task {
            await checkNotificationPermission()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

private extension NotificationSettingsViewModel {
    func observeAppState() {
        // Observe when the app becomes active.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }

    @objc private func appDidBecomeActive() {
        Task {
            await checkNotificationPermission()
        }
    }

    @MainActor
    func checkNotificationPermission() async {
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
