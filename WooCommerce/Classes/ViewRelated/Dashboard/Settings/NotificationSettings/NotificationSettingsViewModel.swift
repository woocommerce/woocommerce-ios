import Combine
import UIKit
import Yosemite
import protocol Storage.StorageManagerType

/// View model for `NotificationSettingsView`
final class NotificationSettingsViewModel: ObservableObject {
    @Published private(set) var notificationsEnabled = false
    @Published var orderNotificationsEnabled = false
    @Published var productReviewNotificationsEnabled = false

    private let notificationCenter: UserNotificationsCenterAdapter
    private let stores: StoresManager
    private let storageManager: StorageManagerType

    private var appStateSubscription: AnyCancellable?

    /// ResultsController: Loads Sites from the Storage Layer.
    ///
    private lazy var siteResultsController: ResultsController<StorageSite> = {
        let predicate = NSPredicate(format: "isWooCommerceActive == YES")
        let nameDescriptor = NSSortDescriptor(keyPath: \StorageSite.name, ascending: true)
        return ResultsController(storageManager: storageManager,
                                 matching: predicate,
                                 sortedBy: [nameDescriptor])
    }()

    init(notificationCenter: UserNotificationsCenterAdapter = UNUserNotificationCenter.current(),
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.notificationCenter = notificationCenter
        self.stores = stores
        self.storageManager = storageManager

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

    @MainActor
    func synchronizeSites(selectedSiteID: Int64?) async {
        await withCheckedContinuation { continuation in
            stores.dispatch(AccountAction.synchronizeSites(selectedSiteID: selectedSiteID) { _ in
                continuation.resume()
            })
        }
    }
}
