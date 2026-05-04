import Foundation
import Networking
import Storage

/// SettingStoreMethods extracts functionality of SettingStore that needs be reused within Yosemite
/// SettingStoreMethods is intentionally internal not to be exposed outside the module
///
internal protocol SettingStoreMethodsProtocol {
    func synchronizeGeneralSiteSettings(siteID: Int64, onCompletion: @escaping (Error?) -> Void)
    func synchronizeProductSiteSettings(siteID: Int64, onCompletion: @escaping (Error?) -> Void)
    func retrieveSiteAPI(siteID: Int64, onCompletion: @escaping (Result<SiteAPI, Error>) -> Void)
    // periphery:ignore
    func retrievePointOfSaleSettings(siteID: Int64) async throws -> [SiteSetting]
    func retrieveCouponSetting(siteID: Int64, onCompletion: @escaping (Result<Bool, Error>) -> Void)
    func enableCouponSetting(siteID: Int64, onCompletion: @escaping (Result<Void, Error>) -> Void)
    func retrieveAnalyticsSetting(siteID: Int64, onCompletion: @escaping (Result<Bool, Error>) -> Void)
    func enableAnalyticsSetting(siteID: Int64, onCompletion: @escaping (Result<Void, Error>) -> Void)
    func retrieveTaxBasedOnSetting(siteID: Int64, onCompletion: @escaping (Result<TaxBasedOnSetting, Error>) -> Void)
    func isFeatureEnabled(siteID: Int64, feature: SiteSettingsFeature) async throws -> Bool
    func retrieveAnalyticsOrderDateType(siteID: Int64) async throws -> AnalyticsOrderDateType
    func updateAnalyticsOrderDateType(siteID: Int64, value: AnalyticsOrderDateType) async throws
}

internal class SettingStoreMethods: SettingStoreMethodsProtocol {
    private let siteSettingsRemote: SiteSettingsRemote
    private let siteAPIRemote: SiteAPIRemote
    private let storageManager: StorageManagerType
    private let network: Network

    init(storageManager: StorageManagerType, network: Network) {
        self.siteSettingsRemote = SiteSettingsRemote(network: network)
        self.siteAPIRemote = SiteAPIRemote(network: network)
        self.network = network
        self.storageManager = storageManager
    }

    /// Synchronizes the general site settings associated with the provided Site ID (if any!).
    ///
    func synchronizeGeneralSiteSettings(siteID: Int64, onCompletion: @escaping (Error?) -> Void) {
        siteSettingsRemote.loadGeneralSettings(for: siteID) { [weak self] (settings, error) in
            guard let settings else {
                onCompletion(error)
                return
            }

            self?.upsertStoredGeneralSettingsInBackground(siteID: siteID, readOnlySiteSettings: settings) {
                onCompletion(nil)
            }
        }
    }

    /// Synchronizes the product site settings associated with the provided Site ID (if any!).
    ///
    func synchronizeProductSiteSettings(siteID: Int64, onCompletion: @escaping (Error?) -> Void) {
        siteSettingsRemote.loadProductSettings(for: siteID) { [weak self] (settings, error) in
            guard let settings else {
                onCompletion(error)
                return
            }

            self?.upsertStoredProductSettingsInBackground(siteID: siteID, readOnlySiteSettings: settings) {
                onCompletion(nil)
            }
        }
    }

    /// Retrieves the site API information associated with the provided Site ID (if any!).
    /// This call does NOT persist returned data into the Storage layer.
    ///
    func retrieveSiteAPI(siteID: Int64, onCompletion: @escaping (Result<SiteAPI, Error>) -> Void) {
        siteAPIRemote.loadAPIInformation(for: siteID, completion: onCompletion)
    }

    /// Retrieves Point of Sale settings
    ///
    // periphery:ignore
    func retrievePointOfSaleSettings(siteID: Int64) async throws -> [SiteSetting] {
        return try await siteSettingsRemote.loadPointOfSaleSettings(for: siteID)
    }

    /// Retrieves the setting for whether coupons are enabled for the specified store
    ///
    func retrieveCouponSetting(siteID: Int64, onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        siteSettingsRemote.loadSetting(for: siteID, settingGroup: .general, settingID: SettingKeys.coupons) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let setting):
                self.upsertSingleStoredSettingInBackground(siteID: siteID, readOnlySiteSetting: setting) {
                    let isEnabled = setting.value == SettingValue.yes
                    onCompletion(.success(isEnabled))
                }
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    /// Enables coupons for the specified store
    ///
    func enableCouponSetting(siteID: Int64, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        siteSettingsRemote.updateSetting(for: siteID, settingGroup: .general, settingID: SettingKeys.coupons, value: SettingValue.yes) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let setting):
                self.upsertSingleStoredSettingInBackground(siteID: siteID, readOnlySiteSetting: setting) {
                    onCompletion(.success(Void()))
                }
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    /// Retrieves the setting for whether WC Analytics are enabled for the specified store
    ///
    func retrieveAnalyticsSetting(siteID: Int64, onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        siteSettingsRemote.loadSetting(for: siteID, settingGroup: .advanced, settingID: SettingKeys.analytics) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let setting):
                self.upsertSingleStoredSettingInBackground(siteID: siteID, readOnlySiteSetting: setting) {
                    let isEnabled = setting.value == SettingValue.yes
                    onCompletion(.success(isEnabled))
                }
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    /// Enables WC Analytics for the specified store
    ///
    func enableAnalyticsSetting(siteID: Int64, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        siteSettingsRemote.updateSetting(for: siteID,
                                            settingGroup: .advanced,
                                            settingID: SettingKeys.analytics,
                                            value: SettingValue.yes) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let setting):
                self.upsertSingleStoredSettingInBackground(siteID: siteID, readOnlySiteSetting: setting) {
                    onCompletion(.success(Void()))
                }
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    /// Retrieves the used address to calculate the tax
    ///
    func retrieveTaxBasedOnSetting(siteID: Int64, onCompletion: @escaping (Result<TaxBasedOnSetting, Error>) -> Void) {
        siteSettingsRemote.loadSetting(for: siteID, settingGroup: .custom("tax"), settingID: SettingKeys.taxBasedOn) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let setting):
                self.upsertSingleStoredSettingInBackground(siteID: siteID, readOnlySiteSetting: setting) {
                    guard let taxBasedOnSetting = TaxBasedOnSetting(backendValue: setting.value) else {
                        onCompletion(.failure(SettingError.parseError))
                        return
                    }

                    onCompletion(.success(taxBasedOnSetting))
                }
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    /// Checks if a specific feature is enabled in the site WC settings.
    ///
    func isFeatureEnabled(siteID: Int64, feature: SiteSettingsFeature) async throws -> Bool {
        try await siteSettingsRemote.isFeatureEnabled(for: siteID, feature: feature)
    }

    /// Retrieves the WooCommerce Analytics order date-type setting (`woocommerce_date_type`).
    ///
    /// Throws `SettingError.parseError` if the response value cannot be mapped to a known type.
    ///
    func retrieveAnalyticsOrderDateType(siteID: Int64) async throws -> AnalyticsOrderDateType {
        let setting = try await siteSettingsRemote.loadAnalyticsOrderDateType(for: siteID)
        return try await parseAndCacheAnalyticsOrderDateType(setting, siteID: siteID)
    }

    /// Updates the WooCommerce Analytics order date-type setting (`woocommerce_date_type`).
    ///
    /// Throws `SettingError.parseError` if the response value cannot be mapped to a known type.
    ///
    func updateAnalyticsOrderDateType(siteID: Int64, value: AnalyticsOrderDateType) async throws {
        let setting = try await siteSettingsRemote.updateAnalyticsOrderDateType(for: siteID, value: value.rawValue)
        _ = try await parseAndCacheAnalyticsOrderDateType(setting, siteID: siteID)
    }

    /// Parses the response value into `AnalyticsOrderDateType` and, only on success, caches the SiteSetting locally.
    /// Throws `SettingError.parseError` (without writing to cache) when the value can't be mapped to a known case.
    private func parseAndCacheAnalyticsOrderDateType(_ setting: Networking.SiteSetting, siteID: Int64) async throws -> AnalyticsOrderDateType {
        guard let dateType = AnalyticsOrderDateType(rawValue: setting.value) else {
            throw SettingError.parseError
        }
        await upsertSingleStoredSetting(siteID: siteID, readOnlySiteSetting: setting)
        return dateType
    }
}

// MARK: - Persistence

private extension SettingStoreMethods {

    /// Updates (OR Inserts) the specified **general** ReadOnly `SiteSetting` Entities **in a background thread**. `onCompletion` will be called
    /// on the main thread!
    ///
    func upsertStoredGeneralSettingsInBackground(siteID: Int64, readOnlySiteSettings: [Networking.SiteSetting], onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ [weak self] storage in
            self?.upsertSettings(readOnlySiteSettings, in: storage, siteID: siteID, settingGroup: SiteSettingGroup.general)
        }, completion: onCompletion, on: .main)
    }

    /// Updates (OR Inserts) the specified **product** ReadOnly `SiteSetting` entities **in a background thread**. `onCompletion` will be called
    /// on the main thread!
    ///
    func upsertStoredProductSettingsInBackground(siteID: Int64, readOnlySiteSettings: [Networking.SiteSetting], onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ [weak self] storage in
            self?.upsertSettings(readOnlySiteSettings, in: storage, siteID: siteID, settingGroup: SiteSettingGroup.product)
        }, completion: onCompletion, on: .main)
    }

    /// Updates (OR Inserts) the specified **advanced** ReadOnly `SiteSetting` entities **in a background thread**. `onCompletion` will be called
    /// on the main thread!
    ///
    func upsertStoredAdvancedSettingsInBackground(siteID: Int64, readOnlySiteSettings: [Networking.SiteSetting], onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ [weak self] storage in
            self?.upsertSettings(readOnlySiteSettings, in: storage, siteID: siteID, settingGroup: SiteSettingGroup.advanced)
        }, completion: onCompletion, on: .main)
    }

    func upsertSettings(_ readOnlySiteSettings: [SiteSetting], in storage: StorageType, siteID: Int64, settingGroup: SiteSettingGroup) {
        let storageSiteSettings = storage.loadSiteSettings(siteID: siteID, settingGroupKey: settingGroup.rawValue)
        // Upsert the settings from the read-only site settings
        for readOnlyItem in readOnlySiteSettings {
            if let existingStorageItem = storageSiteSettings?.first(where: { $0.settingID == readOnlyItem.settingID }) {
                existingStorageItem.update(with: readOnlyItem)
            } else {
                let newStorageItem = storage.insertNewObject(ofType: Storage.SiteSetting.self)
                newStorageItem.update(with: readOnlyItem)
            }
        }

        // Now, remove any objects that exist in storageSiteSettings but not in readOnlySiteSettings
        if let storageSiteSettings {
            storageSiteSettings.forEach({ storageItem in
                if readOnlySiteSettings!.contains(where: { $0.settingID == storageItem.settingID }) {
                    storage.deleteObject(storageItem)
                }
            })
        }
    }

    /// Updates (OR Inserts) a single ReadOnly `SiteSetting` entity **in a background thread**. `onCompletion` will be called
    /// on the main thread!
    ///
    /// Doesn't remove other settings
    ///
    func upsertSingleStoredSettingInBackground(siteID: Int64, readOnlySiteSetting: Networking.SiteSetting, onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ [weak self] storage in
            self?.upsertSingleSetting(readOnlySiteSetting, in: storage, siteID: siteID)
        }, completion: onCompletion, on: .main)
    }

    func upsertSingleStoredSetting(siteID: Int64, readOnlySiteSetting: Networking.SiteSetting) async {
        await withCheckedContinuation { continuation in
            upsertSingleStoredSettingInBackground(siteID: siteID, readOnlySiteSetting: readOnlySiteSetting) {
                continuation.resume()
            }
        }
    }

    func upsertSingleSetting(_ readOnlySiteSetting: SiteSetting, in storage: StorageType, siteID: Int64) {
        let existingStorageItem = storage.loadSiteSetting(siteID: siteID, settingID: readOnlySiteSetting.settingID)

        if let existingStorageItem {
            existingStorageItem.update(with: readOnlySiteSetting)
        } else {
            let newStorageItem = storage.insertNewObject(ofType: Storage.SiteSetting.self)
            newStorageItem.update(with: readOnlySiteSetting)
        }
    }
}

// MARK: - Unit Testing Helpers
//
extension SettingStoreMethods {

    /// Unit Testing Helper: Updates or Inserts the specified **general** ReadOnly SiteSetting entities in the provided Storage instance.
    ///
    func upsertStoredGeneralSiteSettings(siteID: Int64, readOnlySiteSettings: [Networking.SiteSetting], in storage: StorageType) {
        upsertSettings(readOnlySiteSettings, in: storage, siteID: siteID, settingGroup: SiteSettingGroup.general)
    }

    /// Unit Testing Helper: Updates or Inserts the specified **product** ReadOnly SiteSetting entities in the provided Storage instance.
    ///
    func upsertStoredProductSiteSettings(siteID: Int64, readOnlySiteSettings: [Networking.SiteSetting], in storage: StorageType) {
        upsertSettings(readOnlySiteSettings, in: storage, siteID: siteID, settingGroup: SiteSettingGroup.product)
    }
}

// MARK: Definitions
extension SettingStoreMethods {
    /// Settings keys.
    ///
    private enum SettingKeys {
        static let coupons = "woocommerce_enable_coupons"
        static let analytics = "woocommerce_analytics_enabled"
        static let taxBasedOn = "woocommerce_tax_based_on"
    }

    private enum SettingValue {
        static let yes = "yes"
    }
}
