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
}

/// Methods for managing site-specific app settings
///
struct SiteSpecificAppSettingsStoreMethods: SiteSpecificAppSettingsStoreMethodsProtocol {
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
    func getStoreSettings(for siteID: Int64) -> GeneralStoreSettings {
        guard let existingData: GeneralStoreSettingsBySite = try? fileStorage.data(for: generalStoreSettingsFileURL),
              let storeSettings = existingData.storeSettingsBySite[siteID] else {
            return GeneralStoreSettings()
        }

        return storeSettings
    }

    func setStoreSettings(settings: GeneralStoreSettings, for siteID: Int64, onCompletion: ((Result<Void, Error>) -> Void)? = nil) {
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

    func resetStoreSettings() {
        do {
            try fileStorage.deleteFile(at: generalStoreSettingsFileURL)
        } catch {
            DDLogError("⛔️ Deleting store settings file failed. Error: \(error)")
        }
    }

    func setStoreID(siteID: Int64, id: String?) {
        let storeSettings = getStoreSettings(for: siteID)
        let updatedSettings = storeSettings.copy(storeID: id)
        setStoreSettings(settings: updatedSettings, for: siteID)
    }

    func getStoreID(siteID: Int64, onCompletion: (String?) -> Void) {
        let storeSettings = getStoreSettings(for: siteID)
        onCompletion(storeSettings.storeID)
    }
}

// MARK: - Search History
extension SiteSpecificAppSettingsStoreMethods {
    func getSearchTerms(for itemType: POSItemType, siteID: Int64) -> [String] {
        let storeSettings = getStoreSettings(for: siteID)
        let key = itemType.storedSearchHistoryKey
        return storeSettings.searchTermsByKey[key] ?? []
    }

    func setSearchTerms(_ terms: [String], for itemType: POSItemType, siteID: Int64) {
        let storeSettings = getStoreSettings(for: siteID)
        let key = itemType.storedSearchHistoryKey
        var updatedSearchTermsByKey = storeSettings.searchTermsByKey
        updatedSearchTermsByKey[key] = terms
        let updatedSettings = storeSettings.copy(searchTermsByKey: updatedSearchTermsByKey)
        setStoreSettings(settings: updatedSettings, for: siteID)
    }
}

// MARK: - Constants
private enum Constants {
    static let generalStoreSettingsFileName = "general-store-settings.plist"
}
