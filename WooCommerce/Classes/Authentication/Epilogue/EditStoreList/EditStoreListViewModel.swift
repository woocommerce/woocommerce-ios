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

    @Published private(set) var notificationSettingsError: Error?

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

        do {
            isUpdatingNotificationSettings = true
            try await updateNotificationSettings(displayedSiteIDs: displayedSiteIDs, hiddenSiteIDs: hiddenSiteIDs)
            userDefaults.saveHiddenStoreIDs(hiddenSiteIDs)
            onCompletion()
        } catch {
            notificationSettingsError = error
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
        guard let deviceID = pushNotificationManager.deviceID else {
            throw NotificationSettingsError.deviceIDNotFound
        }

        guard let intDeviceID = Int64(deviceID) else {
            throw NotificationSettingsError.malformedDeviceID
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
}

private extension EditStoreListViewModel {
    enum NotificationSettingsError: Error {
        case deviceIDNotFound
        case malformedDeviceID
    }
}
