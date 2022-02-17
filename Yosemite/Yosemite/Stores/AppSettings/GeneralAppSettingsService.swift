import Combine
import Foundation
import Storage

/// Provides access to GeneralAppSettings, persisting changes to disk
///
/// - Warning: GeneralAppSettingsService expects to be the only thing writing to the given fileURL.
/// It doesn't monitors changes to the filesystem, so the contents of `settings` might be outdated if something else writes to the file.
/// Every time changes are saved, all of the settings get overwritten with the in-memory contents,
/// expect settings corruption if there are multiple instances running.
///
public struct GeneralAppSettingsService {
    /// Loads a plist file at a given URL
    ///
    private let fileStorage: FileStorage

    /// URL to the plist file we use to store general settings
    ///
    private let fileURL: URL

    private let settingsSubject: CurrentValueSubject<GeneralAppSettings, Never>

    /// The current settings value
    ///
    var settings: GeneralAppSettings {
        settingsSubject.value
    }

    /// A publisher that emits on every change to settings
    ///
    var settingsPublisher: AnyPublisher<GeneralAppSettings, Never> {
        settingsSubject.eraseToAnyPublisher()
    }

    init(fileStorage: FileStorage, fileURL: URL) {
        self.fileStorage = fileStorage
        self.fileURL = fileURL
        self.settingsSubject = CurrentValueSubject(.default)
        settingsSubject.send(load())
    }

    /// Updates the stored settings with the given settings object
    ///
    func update(settings: GeneralAppSettings) throws {
        settingsSubject.send(settings)
        try fileStorage.write(settings, to: fileURL)
    }

    /// Returns the value for a specific key path of Settings
    ///
    func value<Value>(for keyPath: KeyPath<GeneralAppSettings, Value>) -> Value {
        settings[keyPath: keyPath]
    }

    /// Returns a publisher that emits changes when the setting for the specified key path changes
    ///
    func publisher<Value: Equatable>(for keyPath: KeyPath<GeneralAppSettings, Value>) -> AnyPublisher<Value, Never> {
        settingsPublisher
            .map(keyPath)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    /// Updates the stored setting for the specified key path
    ///
    func update<Value>(_ value: Value, for keyPath: WritableKeyPath<GeneralAppSettings, Value>) throws {
        var newSettings = settings
        newSettings[keyPath: keyPath] = value
        try update(settings: newSettings)
    }

    /// Returns a nested value from a dictionary stored in settings.
    ///
    func pluck<Key, Value>(from keyPath: KeyPath<GeneralAppSettings, [Key: Value]>, key: Key) -> Value? {
        let container = settings[keyPath: keyPath]
        let value = container[key]
        return value
    }

    /// Updates a nested value on a dictionary stored in settings.
    ///
    func patch<Key, Value>(_ value: Value, into keyPath: WritableKeyPath<GeneralAppSettings, [Key: Value]>, key: Key) throws {
        var container = settings[keyPath: keyPath]
        container[key] = value
        try update(container, for: keyPath)
    }
}

private extension GeneralAppSettingsService {
    func load() -> GeneralAppSettings {
        guard let storedSettings: GeneralAppSettings = try? fileStorage.data(for: fileURL) else {
            return .default
        }
        return storedSettings
    }
}
