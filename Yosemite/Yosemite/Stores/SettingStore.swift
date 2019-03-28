import Foundation
import Networking
import Storage


// MARK: - SettingStore
//
public class SettingStore: Store {

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: SettingAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? SettingAction else {
            assertionFailure("SettingStore received an unsupported action")
            return
        }

        switch action {
        case .synchronizeGeneralSiteSettings(let siteID, let onCompletion):
            synchronizeGeneralSiteSettings(siteID: siteID, onCompletion: onCompletion)
        case .synchronizeProductSiteSettings(let siteID, let onCompletion):
            synchronizeProductSiteSettings(siteID: siteID, onCompletion: onCompletion)
        case .retrieveSiteAPI(let siteID, let onCompletion):
            retrieveSiteAPI(siteID: siteID, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension SettingStore {

    /// Synchronizes the general site settings associated with the provided Site ID (if any!).
    ///
    func synchronizeGeneralSiteSettings(siteID: Int, onCompletion: @escaping (Error?) -> Void) {
        let remote = SiteSettingsRemote(network: network)
        remote.loadGeneralSettings(for: siteID) { [weak self] (settings, error) in
            guard let settings = settings else {
                onCompletion(error)
                return
            }

            self?.upsertStoredGeneralSiteSettings(siteID: siteID, readOnlySiteSettings: settings)
            onCompletion(nil)
        }
    }

    /// Synchronizes the product site settings associated with the provided Site ID (if any!).
    ///
    func synchronizeProductSiteSettings(siteID: Int, onCompletion: @escaping (Error?) -> Void) {
        let remote = SiteSettingsRemote(network: network)
        remote.loadProductSettings(for: siteID) { [weak self] (settings, error) in
            guard let settings = settings else {
                onCompletion(error)
                return
            }

            self?.upsertStoredProductSiteSettings(siteID: siteID, readOnlySiteSettings: settings)
            onCompletion(nil)
        }
    }

    /// Retrieves the site API information associated with the provided Site ID (if any!).
    /// This call does NOT persist returned data into the Storage layer.
    ///
    func retrieveSiteAPI(siteID: Int, onCompletion: @escaping (SiteAPI?, Error?) -> Void) {
        let remote = SiteAPIRemote(network: network)
        remote.loadAPIInformation(for: siteID) { (siteAPI, error) in
            onCompletion(siteAPI, error)
        }
    }
}


// MARK: - Persistence
//
extension SettingStore {

    /// Updates (OR Inserts) the specified general ReadOnly SiteSetting Entities into the Storage Layer.
    ///
    func upsertStoredGeneralSiteSettings(siteID: Int, readOnlySiteSettings: [Networking.SiteSetting]) {
        assert(Thread.isMainThread)
        let storage = storageManager.viewStorage

        // Upsert the settings from the read-only site settings
        for readOnlyItem in readOnlySiteSettings {
            if let existingStorageItem = storage.loadSiteSetting(siteID: siteID, settingID: readOnlyItem.settingID) {
                existingStorageItem.update(with: readOnlyItem)
            } else {
                let newStorageItem = storage.insertNewObject(ofType: Storage.SiteSetting.self)
                newStorageItem.update(with: readOnlyItem)
            }
        }

        // Now, remove any objects that exist in storageSiteSettings but not in readOnlySiteSettings
        if let storageSiteSettings = storage.loadSiteSettings(siteID: siteID) {
            storageSiteSettings.forEach({ storageItem in
                if readOnlySiteSettings.first(where: { $0.settingID == storageItem.settingID } ) == nil {
                    storage.deleteObject(storageItem)
                }
            })
        }

        storage.saveIfNeeded()
    }

    /// Updates (OR Inserts) the specified product ReadOnly SiteSetting Entities into the Storage Layer.
    ///
    func upsertStoredProductSiteSettings(siteID: Int, readOnlySiteSettings: [Networking.SiteSetting]) {
        assert(Thread.isMainThread)
        let storage = storageManager.viewStorage

        // Upsert the settings from the read-only site settings
        for readOnlyItem in readOnlySiteSettings {
            if let existingStorageItem = storage.loadSiteSetting(siteID: siteID, settingID: readOnlyItem.settingID) {
                existingStorageItem.update(with: readOnlyItem)
            } else {
                let newStorageItem = storage.insertNewObject(ofType: Storage.SiteSetting.self)
                newStorageItem.update(with: readOnlyItem)
            }
        }

        // Now, remove any objects that exist in storageSiteSettings but not in readOnlySiteSettings
        if let storageSiteSettings = storage.loadSiteSettings(siteID: siteID) {
            storageSiteSettings.forEach({ storageItem in
                if readOnlySiteSettings.first(where: { $0.settingID == storageItem.settingID } ) == nil {
                    storage.deleteObject(storageItem)
                }
            })
        }

        storage.saveIfNeeded()
    }
}
