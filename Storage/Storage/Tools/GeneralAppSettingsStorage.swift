import Foundation

// MARK: - Public API

/// Provides access to the stored GeneralAppSettings
///
public struct GeneralAppSettingsStorage {
    private let fileStorage: FileStorage

    public init(fileStorage: FileStorage) {
        self.fileStorage = fileStorage
    }

    /// Reads the value of the stored setting for the given key path
    ///
    public func value<T>(for setting: KeyPath<GeneralAppSettings, T>) -> T {
        let settings = loadOrCreateGeneralAppSettings()
        return settings[keyPath: setting]
    }

    /// Writes the value to the stored setting for the given key path
    ///
    public func setValue<T>(_ value: T, for setting: WritableKeyPath<GeneralAppSettings, T>) throws {
        var settings = loadOrCreateGeneralAppSettings()
        settings[keyPath: setting] = value
        try saveGeneralAppSettings(settings)
    }

    /// Returns the GeneralAppSettings object
    ///
    public var settings: GeneralAppSettings {
        loadOrCreateGeneralAppSettings()
    }

    /// Writes a new GeneralAppSettings object to storage
    ///
    public func saveSettings(_ settings: GeneralAppSettings) throws {
        try saveGeneralAppSettings(settings)
    }
}

// MARK: - Storage
private extension GeneralAppSettingsStorage {

    /// Load the `GeneralAppSettings` from file or create an empty one if it doesn't exist.
    func loadOrCreateGeneralAppSettings() -> GeneralAppSettings {
        guard let settings: GeneralAppSettings = try? fileStorage.data(for: Constants.generalAppSettingsFileURL) else {
            return GeneralAppSettings(installationDate: nil,
                                      feedbacks: [:],
                                      isViewAddOnsSwitchEnabled: false,
                                      isProductSKUInputScannerSwitchEnabled: false,
                                      isCouponManagementSwitchEnabled: false,
                                      knownCardReaders: [],
                                      lastEligibilityErrorInfo: nil)
        }

        return settings
    }

    /// Save the `GeneralAppSettings` to the appropriate file.
    func saveGeneralAppSettings(_ settings: GeneralAppSettings) throws {
        try fileStorage.write(settings, to: Constants.generalAppSettingsFileURL)
    }
}

// MARK: - Constants

/// Constants
///
private enum Constants {

    // MARK: File Names
    static let generalAppSettingsFileName = "general-app-settings.plist"
    static let generalAppSettingsFileURL: URL! = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent(generalAppSettingsFileName)
    }()
}
