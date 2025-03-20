import Combine
import UIKit

/// View model for `NotificationSettingsView`
final class NotificationSettingsViewModel: ObservableObject {
    @Published private(set) var notificationsEnabled: Bool?
    @Published var orderNotificationsEnabled = false
    @Published var productReviewNotificationsEnabled = false

    private let notificationCenter: UserNotificationsCenterAdapter
    private var appStateSubscription: AnyCancellable?

    init(notificationCenter: UserNotificationsCenterAdapter = UNUserNotificationCenter.current()) {
        self.notificationCenter = notificationCenter

        observeAppState()
    }

    @MainActor
    func checkNotificationPermission() async {
        let isEnabled = await withCheckedContinuation { continuation in
            notificationCenter.loadAuthorizationStatus(queue: .main) { status in
                switch status {
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
}
