import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// View model for `EditStoreListView`
///
final class EditStoreListViewModel: ObservableObject {
    /// All available sites to be displayed on the store picker
    let availableSites: [Site]

    let currentlySelectedSite: Site?

    /// Sites selected to be displayed on the store picker
    @Published var selectedSites: Set<Site>

    @Published private(set) var isUpdatingNotificationSettings = false

    @Published var shouldShowErrorAlert = false

    var hasChanges: Bool {
        selectedSites != Set(originalSelectedSites)
    }

    private let originalSelectedSites: [Site]
    private let stores: StoresManager
    private let pushNotificationManager: PushNotesManager
    private let userDefaults: UserDefaults
    private let analytics: Analytics
    private let onCompletion: () -> Void

    init(availableSites: [Site],
         displayedSites: [Site],
         currentlySelectedSite: Site?,
         stores: StoresManager = ServiceLocator.stores,
         pushNotificationManager: PushNotesManager = ServiceLocator.pushNotesManager,
         userDefaults: UserDefaults = .standard,
         analytics: Analytics = ServiceLocator.analytics,
         onCompletion: @escaping () -> Void) {
        self.availableSites = availableSites.filter { $0.siteID != currentlySelectedSite?.siteID }
        self.currentlySelectedSite = currentlySelectedSite
        self.originalSelectedSites = displayedSites
        self.selectedSites = Set(displayedSites)
        self.stores = stores
        self.pushNotificationManager = pushNotificationManager
        self.userDefaults = userDefaults
        self.analytics = analytics
        self.onCompletion = onCompletion
    }

    @MainActor
    func saveChanges() async {
        let hiddenSites = Set(availableSites).subtracting(selectedSites)
        let hiddenSiteIDs = Array(hiddenSites).map { $0.siteID }
        let displayedSiteIDs = Array(selectedSites).map { $0.siteID }

        let originalHiddenSiteIDs = Set(availableSites.map(\.siteID)).subtracting(originalSelectedSites.map(\.siteID))
        let newlyEnabledSiteIDs = displayedSiteIDs.filter { originalHiddenSiteIDs.contains($0) }

        analytics.track(event: .SitePicker.listSaveButtonTapped(hiddenSiteCount: hiddenSiteIDs.count))
        shouldShowErrorAlert = false
        isUpdatingNotificationSettings = true
        do {
            await registerNewlyEnabledSitesForSelfDrivenPushNotifications(newlyEnabledSiteIDs: newlyEnabledSiteIDs)

            // Sites registered with Woo should be disabled in WPCom to avoid duplicate notifications
            let siteIDsRegisteredForWooPNs = Set(pushNotificationManager.siteIDsRegisteredForWooPNs)
            let wpcomEnabledSiteIDs = displayedSiteIDs.filter { !siteIDsRegisteredForWooPNs.contains($0) }
            let wpcomDisabledSiteIDs = hiddenSiteIDs + displayedSiteIDs.filter { siteIDsRegisteredForWooPNs.contains($0) }

            try await updateNotificationSettings(displayedSiteIDs: wpcomEnabledSiteIDs, hiddenSiteIDs: wpcomDisabledSiteIDs)
            await unregisterHiddenSitesFromSelfDrivenPushNotifications(hiddenSiteIDs: hiddenSiteIDs)
            userDefaults.saveHiddenStoreIDs(hiddenSiteIDs)
            analytics.track(event: .SitePicker.listEditSavingSuccess())
            onCompletion()
        } catch {
            shouldShowErrorAlert = true
            analytics.track(event: .SitePicker.listEditSavingFailure(error: error))
        }
        isUpdatingNotificationSettings = false
    }
}

// MARK: - Helper methods for selection
extension EditStoreListViewModel {

    /// Checks if the given site is selected.
    func isSelected(_ site: Site) -> Bool {
        selectedSites.contains(site)
    }

    /// Checks if the given site is the last selected item.
    /// This is used to disable that row, so it can't be deselected.
    func isLastSelected(_ site: Site) -> Bool {
        isSelected(site) && selectedSites.count == 1
    }

    /// Selects or deselects the given site.
    func toggleSelection(_ site: Site) {
        if selectedSites.contains(site) {
            selectedSites.remove(site)
        } else {
            selectedSites.insert(site)
        }
    }
}

private extension EditStoreListViewModel {
    @MainActor
    func updateNotificationSettings(displayedSiteIDs: [Int64],
                                    hiddenSiteIDs: [Int64]) async throws {
        guard let deviceID = pushNotificationManager.deviceID,
            let intDeviceID = Int64(deviceID) else {
            /// skip updating notification settings if no device ID is found
            return
        }

        let settings = NotificationSettings(deviceID: intDeviceID,
                                            enabledSites: displayedSiteIDs,
                                            disabledSites: hiddenSiteIDs)
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(AccountAction.updateNotificationSettings(notificationSettings: settings, onCompletion: { result in
                continuation.resume(with: result)
            }))
        }
    }

    /// Registers newly enabled sites for the self-driven push notification system.
    /// This is best-effort — failures are logged but do not block the save operation.
    /// Sites that fail to register will fall back to WPCom push notifications via `updateNotificationSettings`.
    @MainActor
    func registerNewlyEnabledSitesForSelfDrivenPushNotifications(newlyEnabledSiteIDs: [Int64]) async {
        await withTaskGroup(of: Void.self) { group in
            for siteID in newlyEnabledSiteIDs {
                group.addTask { [weak self] in
                    guard let self else { return }
                    do {
                        try await pushNotificationManager.registerSiteForSelfDrivenPushNotifications(siteID)
                    } catch {
                        DDLogError("⛔️ Failed to register site \(siteID) for self-driven push notifications: \(error)")
                    }
                }
            }
        }
    }

    /// Unregisters hidden sites from the self-driven push notification system.
    /// This is best-effort — failures are logged but do not block the save operation.
    @MainActor
    func unregisterHiddenSitesFromSelfDrivenPushNotifications(hiddenSiteIDs: [Int64]) async {
        guard let tokenString = pushNotificationManager.wooPushNotificationToken,
              let tokenID = Int64(tokenString) else {
            return
        }

        let registeredSiteIDs = pushNotificationManager.siteIDsRegisteredForWooPNs
        let siteIDsToUnregister = hiddenSiteIDs.filter { registeredSiteIDs.contains($0) }

        for siteID in siteIDsToUnregister {
            do {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    stores.dispatch(NotificationAction.unregisterFromSelfDrivenPushNotifications(
                        siteID: siteID,
                        tokenID: tokenID,
                        // Force Jetpack tunnel: the hidden site is never the currently selected site,
                        // so the REST fallback in `RequestConverter` would route to the wrong host.
                        // The Jetpack tunnel carries `siteID` in the URL path and always reaches the
                        // correct site.
                        availableAsRESTRequest: false,
                        onCompletion: { result in
                            continuation.resume(with: result)
                        }
                    ))
                }
                pushNotificationManager.unmarkSiteAsRegisteredForWooPNs(siteID)
            } catch {
                DDLogError("⛔️ Failed to unregister site \(siteID) from self-driven push notifications: \(error)")
            }
        }
    }
}
