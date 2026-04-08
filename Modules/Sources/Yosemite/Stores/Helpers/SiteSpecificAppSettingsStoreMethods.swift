import Foundation
import Storage

public protocol SiteSpecificAppSettingsStoreMethodsProtocol {
    func getStoreSettings(for siteID: Int64) -> GeneralStoreSettings
    func setStoreSettings(settings: GeneralStoreSettings, for siteID: Int64, onCompletion: ((Result<Void, Error>) -> Void)?)
    func resetStoreSettings()
    func setStoreID(siteID: Int64, id: String?)
    func getStoreID(siteID: Int64, onCompletion: (String?) -> Void)

    // Search history methods
    func getSearchTerms(for itemType: POSItemType, siteID: Int64) -> [String]
    func setSearchTerms(_ terms: [String], for itemType: POSItemType, siteID: Int64)

    // POS sync eligibility tracking
    func getPOSLastOpenedDate(siteID: Int64) -> Date?
    func setPOSLastOpenedDate(siteID: Int64, date: Date)
    func getFirstPOSCatalogSyncDate(siteID: Int64) -> Date?
    func setFirstPOSCatalogSyncDate(siteID: Int64, date: Date)

    // POS local catalog cellular data
    func setPOSLocalCatalogCellularDataAllowed(siteID: Int64, allowed: Bool)
    func getPOSLocalCatalogCellularDataAllowed(siteID: Int64) -> Bool

    // POS sunset warning
    func getSunsetWarningLastShownDate(siteID: Int64) -> Date?
    func setSunsetWarningLastShownDate(siteID: Int64, date: Date)
}

/// Methods for managing site-specific app settings
///
public struct SiteSpecificAppSettingsStoreMethods: SiteSpecificAppSettingsStoreMethodsProtocol {
    private let fileStorage: FileStorage
    private let generalStoreSettingsFileURL: URL

    /// Default URL for storing general store settings
    ///
    public static var defaultGeneralStoreSettingsFileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent(Constants.generalStoreSettingsFileName)
    }

    public init(fileStorage: FileStorage, generalStoreSettingsFileURL: URL = defaultGeneralStoreSettingsFileURL) {
        self.fileStorage = fileStorage
        self.generalStoreSettingsFileURL = generalStoreSettingsFileURL
    }
}

// MARK: - Store Settings
extension SiteSpecificAppSettingsStoreMethods {
    public func getStoreSettings(for siteID: Int64) -> GeneralStoreSettings {
        guard let existingData: GeneralStoreSettingsBySite = try? fileStorage.data(for: generalStoreSettingsFileURL),
              let storeSettings = existingData.storeSettingsBySite[siteID] else {
            return GeneralStoreSettings()
        }

        return storeSettings
    }

    public func setStoreSettings(settings: GeneralStoreSettings, for siteID: Int64, onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
        var storeSettingsBySite: [Int64: GeneralStoreSettings] = [:]
        if let existingData: GeneralStoreSettingsBySite = try? fileStorage.data(for: generalStoreSettingsFileURL) {
            storeSettingsBySite = existingData.storeSettingsBySite
        }

        storeSettingsBySite[siteID] = settings

        do {
            try fileStorage.write(GeneralStoreSettingsBySite(storeSettingsBySite: storeSettingsBySite), to: generalStoreSettingsFileURL)
            onCompletion?(.success(()))
        } catch {
            onCompletion?(.failure(error))
            DDLogError("⛔️ Saving store settings to file failed. Error: \(error)")
        }
    }

    public func resetStoreSettings() {
        do {
            try fileStorage.deleteFile(at: generalStoreSettingsFileURL)
        } catch {
            DDLogError("⛔️ Deleting store settings file failed. Error: \(error)")
        }
    }

    public func setStoreID(siteID: Int64, id: String?) {
        let storeSettings = getStoreSettings(for: siteID)
        let updatedSettings = storeSettings.copy(storeID: id)
        setStoreSettings(settings: updatedSettings, for: siteID)
    }

    public func getStoreID(siteID: Int64, onCompletion: (String?) -> Void) {
        let storeSettings = getStoreSettings(for: siteID)
        onCompletion(storeSettings.storeID)
    }
}

// MARK: - Search History
extension SiteSpecificAppSettingsStoreMethods {
    public func getSearchTerms(for itemType: POSItemType, siteID: Int64) -> [String] {
        let storeSettings = getStoreSettings(for: siteID)
        let key = itemType.storedSearchHistoryKey
        return storeSettings.searchTermsByKey[key] ?? []
    }

    public func setSearchTerms(_ terms: [String], for itemType: POSItemType, siteID: Int64) {
        let storeSettings = getStoreSettings(for: siteID)
        let key = itemType.storedSearchHistoryKey
        var updatedSearchTermsByKey = storeSettings.searchTermsByKey
        updatedSearchTermsByKey[key] = terms
        let updatedSettings = storeSettings.copy(searchTermsByKey: updatedSearchTermsByKey)
        setStoreSettings(settings: updatedSettings, for: siteID)
    }
}

// MARK: - POS sync eligibility tracking
extension SiteSpecificAppSettingsStoreMethods {
    public func getPOSLastOpenedDate(siteID: Int64) -> Date? {
        getStoreSettings(for: siteID).lastPOSOpenedDate
    }

    public func setPOSLastOpenedDate(siteID: Int64, date: Date) {
        let storeSettings = getStoreSettings(for: siteID)
        let updatedSettings = storeSettings.copy(lastPOSOpenedDate: date)
        setStoreSettings(settings: updatedSettings, for: siteID)
    }

    public func getFirstPOSCatalogSyncDate(siteID: Int64) -> Date? {
        getStoreSettings(for: siteID).firstPOSCatalogSyncDate
    }

    public func setFirstPOSCatalogSyncDate(siteID: Int64, date: Date) {
        let storeSettings = getStoreSettings(for: siteID)
        let updatedSettings = storeSettings.copy(firstPOSCatalogSyncDate: date)
        setStoreSettings(settings: updatedSettings, for: siteID)
    }
}

// MARK: - POS local catalog cellular data
extension SiteSpecificAppSettingsStoreMethods {
    public func setPOSLocalCatalogCellularDataAllowed(siteID: Int64, allowed: Bool) {
        let storeSettings = getStoreSettings(for: siteID)
        let updatedSettings = storeSettings.copy(syncPOSCatalogOverCellular: allowed)
        setStoreSettings(settings: updatedSettings, for: siteID)
    }

    public func getPOSLocalCatalogCellularDataAllowed(siteID: Int64) -> Bool {
        getStoreSettings(for: siteID).syncPOSCatalogOverCellular
    }
}

extension SiteSpecificAppSettingsStoreMethods {
    public func getSunsetWarningLastShownDate(siteID: Int64) -> Date? {
        getStoreSettings(for: siteID).lastSunsetWarningShownDate
    }

    public func setSunsetWarningLastShownDate(siteID: Int64, date: Date) {
        let storeSettings = getStoreSettings(for: siteID)
        let updatedSettings = storeSettings.copy(lastSunsetWarningShownDate: date)
        setStoreSettings(settings: updatedSettings, for: siteID)
    }
}

// MARK: - Constants
private enum Constants {
    static let generalStoreSettingsFileName = "general-store-settings.plist"
}
