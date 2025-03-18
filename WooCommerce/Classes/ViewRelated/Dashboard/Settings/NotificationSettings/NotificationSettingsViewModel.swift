import Combine
import UIKit

/// View model for `NotificationSettingsView`
final class NotificationSettingsViewModel: ObservableObject {
    @Published private(set) var notificationsEnabled = false
    @Published var orderNotificationsEnabled = false
    @Published var productReviewNotificationsEnabled = false

    private let notificationCenter: UNUserNotificationCenter
    private var appStateSubscription: AnyCancellable?

    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter

        observeAppState()
        updateNotificationStateIfNeeded()
    }
}

private extension NotificationSettingsViewModel {
    func observeAppState() {
        // Observe when the app becomes active.
        appStateSubscription = NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.updateNotificationStateIfNeeded()
            }
    }

    func updateNotificationStateIfNeeded() {
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
