import Combine
import Foundation
import Storage

public struct GeneralAppSettingsService {
    /// Loads a plist file at a given URL
    ///
    private let fileStorage: FileStorage

    /// URL to the plist file we use to store general settings
    ///
    private let fileURL: URL

    private let settingsSubject: CurrentValueSubject<GeneralAppSettings, Never>

    var settings: GeneralAppSettings {
        settingsSubject.value
    }

    var settingsPublisher: AnyPublisher<GeneralAppSettings, Never> {
        settingsSubject.eraseToAnyPublisher()
    }

    init(fileStorage: FileStorage, fileURL: URL) {
        self.fileStorage = fileStorage
        self.fileURL = fileURL
        self.settingsSubject = CurrentValueSubject(.default)
        settingsSubject.send(load())
    }

    func update(settings: GeneralAppSettings) throws {
        settingsSubject.send(settings)
        try fileStorage.write(settings, to: fileURL)
    }

    func value<Value>(for keyPath: KeyPath<GeneralAppSettings, Value>) -> Value {
        settings[keyPath: keyPath]
    }

    func publisher<Value>(for keyPath: KeyPath<GeneralAppSettings, Value>) -> AnyPublisher<Value, Never> {
        settingsPublisher.map(keyPath).eraseToAnyPublisher()
    }

    func update<Value>(_ value: Value, for keyPath: WritableKeyPath<GeneralAppSettings, Value>) throws {
        var newSettings = settings
        newSettings[keyPath: keyPath] = value
        try update(settings: newSettings)
    }

    func pluck<Key, Value>(from keyPath: KeyPath<GeneralAppSettings, [Key: Value]>, key: Key) -> Value? {
        let container = settings[keyPath: keyPath]
        let value = container[key]
        return value
    }

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
