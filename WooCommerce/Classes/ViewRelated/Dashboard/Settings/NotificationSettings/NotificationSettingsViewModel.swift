import Combine
import UIKit
import Yosemite
import WooFoundation
import protocol Storage.StorageManagerType

/// View model for `NotificationSettingsView`
final class NotificationSettingsViewModel: ObservableObject {
    @Published private(set) var notificationsEnabled: Bool?
    @Published private(set) var sites: [Site] = []
    @Published private(set) var isLoadingSiteSettings = true
    @Published private(set) var siteSettings: NotificationSettings?

    @Published private(set) var isSavingSettings = false

    @Published var notice: Notice?

    @Published var loadingSiteSettingsFailed = false
    @Published var savingSiteSettingsFailed = false

    var hasSiteSettingsChanges: Bool {
        siteSettings != initialSiteSettings
    }

    var shouldShowSiteList: Bool {
        guard currentDeviceID != nil else {
            return false
        }
        return isLoadingSiteSettings || siteSettings != nil
    }

    private let notificationCenter: UserNotificationsCenterAdapter
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let analytics: Analytics
    private let siteIDsRegisteredForWooPNs: Set<Int64>

    let currentDeviceID: String?

    private var appStateSubscription: AnyCancellable?

    private var initialSiteSettings: NotificationSettings?

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
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         pushNotificationManager: PushNotesManager = ServiceLocator.pushNotesManager,
         analytics: Analytics = ServiceLocator.analytics) {
        self.notificationCenter = notificationCenter
        self.stores = stores
        self.storageManager = storageManager
        self.siteIDsRegisteredForWooPNs = Set(pushNotificationManager.siteIDsRegisteredForWooPNs)
        self.currentDeviceID = pushNotificationManager.deviceID
        self.analytics = analytics

        observeAppState()
        configureResultsController()
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
    func synchronizeSites() async {
        await withCheckedContinuation { continuation in
            stores.dispatch(AccountAction.synchronizeSites(selectedSiteID: nil) { _ in
                continuation.resume()
            })
        }
    }

    @MainActor
    func retrieveNotificationSettings() async {
        guard let currentDeviceID, let id = Int64(currentDeviceID) else {
            return
        }
        loadingSiteSettingsFailed = false
        isLoadingSiteSettings = true
        do {
            siteSettings = try await withCheckedThrowingContinuation { continuation in
                stores.dispatch(AccountAction.loadNotificationSettings(deviceID: id) { result in
                    continuation.resume(with: result)
                })
            }
            initialSiteSettings = siteSettings
        } catch {
            DDLogError("⛔️ Error retrieving notification settings: \(error)")
            loadingSiteSettingsFailed = true
        }
        isLoadingSiteSettings = false
    }

    func loadSettings(for site: Site) -> NotificationSettings.Device? {
        if let setting = siteSettings?.blogs.first(where: { $0.blogID == site.siteID }),
           let deviceID = currentDeviceID,
           let device = setting.devices.first(where: { $0.deviceID == Int64(deviceID) }) {
            return device
        }
        return nil
    }

    func updateSettings(siteID: Int64,
                        ordersNotificationsEnabled: Bool,
                        productReviewsNotificationsEnabled: Bool) {
        guard let siteSettings,
              let currentDeviceID else {
            return
        }

        analytics.track(.notificationSettingsUpdateButtonTapped)

        var updatedBlogs: [NotificationSettings.Blog] = []
        for blog in siteSettings.blogs {
            if blog.blogID == siteID {
                var updatedDevices: [NotificationSettings.Device] = []
                for device in blog.devices {
                    if device.deviceID == Int64(currentDeviceID) {
                        updatedDevices.append(device.copy(newComment: productReviewsNotificationsEnabled,
                                                          storeOrder: ordersNotificationsEnabled))
                    } else {
                        updatedDevices.append(device)
                    }
                }
                updatedBlogs.append(blog.copy(devices: updatedDevices))
            } else {
                updatedBlogs.append(blog)
            }
        }

        self.siteSettings = NotificationSettings(blogs: updatedBlogs)
    }

    @MainActor
    func saveSettings() async {
        guard let siteSettings else {
            return
        }
        analytics.track(.notificationSettingsSaveButtonTapped)
        savingSiteSettingsFailed = false
        isSavingSettings = true
        do {
            try await withCheckedThrowingContinuation { continuation in
                stores.dispatch(AccountAction.updateNotificationSettings(notificationSettings: siteSettings) { result in
                    continuation.resume(with: result)
                })
            }
            initialSiteSettings = siteSettings // to ensure that checking for changes works
            notice = Notice(title: Localization.successNotice)
            analytics.track(.notificationSettingsSavingSuccess)
        } catch {
            DDLogError("⛔️ Error saving notification settings: \(error)")
            savingSiteSettingsFailed = true
            analytics.track(.notificationSettingsSavingFailed, withError: error)
        }
        isSavingSettings = false
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

    func configureResultsController() {
        siteResultsController.onDidChangeContent = { [weak self] in
            self?.updateSiteList()
        }
        siteResultsController.onDidResetContent = { [weak self] in
            self?.updateSiteList()
        }

        do {
            try siteResultsController.performFetch()
            updateSiteList()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    func updateSiteList() {
        sites = siteResultsController.fetchedObjects.filter { site in
            siteIDsRegisteredForWooPNs.contains(site.siteID) == false
        }
    }
}

extension NotificationSettingsViewModel {
    enum Localization {
        static let successNotice = NSLocalizedString(
            "notificationSettingsViewModel.successNotice",
            value: "Settings saved!",
            comment: "Notice displayed when saving notification settings succeeds."
        )
    }
}
