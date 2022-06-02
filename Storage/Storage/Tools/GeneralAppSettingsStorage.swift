import Foundation
import Combine

// MARK: - Public API

/// Provides access to the stored GeneralAppSettings
///
public struct GeneralAppSettingsStorage {
    private let fileStorage: FileStorage

    /// This subject is used internally to force a refresh of any settings publisher.
    /// Every time the underlying settings change, we should emit a value here.
    ///
    /// Since there is no guarantee that there will be a single instance of GeneralAppSettingsStorage,
    /// we use a shared static property so that any instance that writes changes to settings emits a
    /// value that would refresh the data on any other instance.
    ///
    private static let refreshSubject = CurrentValueSubject<Void, Never>(())

    public init(fileStorage: FileStorage = PListFileStorage()) {
        self.fileStorage = fileStorage
    }

    /// Reads the value of the stored setting for the given key path
    ///
    public func value<T>(for setting: KeyPath<GeneralAppSettings, T>) -> T {
        let settings = loadOrCreateGeneralAppSettings()
        return settings[keyPath: setting]
    }

    /// Returns a publisher that emits updates every time the value at the given key path changes.
    ///
    public func publisher<T>(for setting: KeyPath<GeneralAppSettings, T>) -> AnyPublisher<T, Never> where T: Equatable {
        settingsPublisher
            .map(setting)
            .removeDuplicates()
            .eraseToAnyPublisher()
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

    /// Returns a publisher that emits updates every time the settings change..
    ///
    public var settingsPublisher: AnyPublisher<GeneralAppSettings, Never> {
        Self.refreshSubject
            .map({ settings })
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    /// Writes a new GeneralAppSettings object to storage
    ///
    public func saveSettings(_ settings: GeneralAppSettings) throws {
        try saveGeneralAppSettings(settings)
        Self.refreshSubject.send(())
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
