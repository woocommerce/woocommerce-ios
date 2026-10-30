import XCTest
import Storage

final class GeneralAppSettingsStorageTests: XCTestCase {
    private var fileStorage: MockInMemoryStorage!
    private var storage: GeneralAppSettingsStorage!

    override func setUp() {
        fileStorage = MockInMemoryStorage()
        storage = GeneralAppSettingsStorage(fileStorage: fileStorage)
    }

    override func tearDown() {
        storage = nil
        fileStorage = nil
    }

    func test_default_settings_when_settings_file_does_not_exist() {
        // Given

        // Make sure settings file doesn't exist
        XCTAssertTrue(fileStorage.data.isEmpty)

        // When
        let settings = storage.settings

        // Then
        XCTAssertEqual(settings, GeneralAppSettings.default)
    }

    func test_save_settings_saves_to_file() throws {
        // Given

        // Make sure settings file doesn't exist
        XCTAssertTrue(fileStorage.data.isEmpty)

        // When
        var settings = GeneralAppSettings.default
        settings.installationDate = .init()
        try storage.saveSettings(settings)

        // Then
        XCTAssertTrue(fileStorage.dataWriteIsHit)
        XCTAssertEqual(storage.settings, settings)
    }

    func test_settings_publisher_publishes_values() throws {
        // Given
        var receivedSettings = [GeneralAppSettings]()
        let cancelable = storage.settingsPublisher.sink { settings in
            receivedSettings.append(settings)
        }

        let settings1 = GeneralAppSettings.default
        var settings2 = settings1
        settings2.knownCardReaders = ["READER2"]

        // When
        try storage.saveSettings(settings1)
        try storage.saveSettings(settings2)

        // Then
        XCTAssertEqual(receivedSettings.count, 2)
        XCTAssertEqual(receivedSettings, [settings1, settings2])

        // Tear down
        cancelable.cancel()
    }

    func test_settings_publisher_does_not_publish_duplicates() throws {
        // Given
        var receivedSettings = [GeneralAppSettings]()
        let cancelable = storage.settingsPublisher.sink { settings in
            receivedSettings.append(settings)
        }

        let settings1 = GeneralAppSettings.default
        let settings2 = GeneralAppSettings.default

        // When
        try storage.saveSettings(settings1)
        try storage.saveSettings(settings2)

        // Then
        XCTAssertEqual(receivedSettings.count, 1)
        XCTAssertEqual(receivedSettings, [settings1])

        // Tear down
        cancelable.cancel()
    }

    func test_settings_publisher_when_another_instance_saves_then_publishes_new_value() throws {
        // Given
        let otherStorage = GeneralAppSettingsStorage(fileStorage: fileStorage)
        var receivedSettings = [GeneralAppSettings]()
        let cancelable = storage.settingsPublisher.sink { settings in
            receivedSettings.append(settings)
        }

        var newSettings = GeneralAppSettings.default
        newSettings.knownCardReaders = ["READER2"]

        // When
        try otherStorage.saveSettings(newSettings)

        // Then
        XCTAssertEqual(receivedSettings, [GeneralAppSettings.default, newSettings])

        // Tear down
        cancelable.cancel()
    }

    func test_settings_publisher_when_another_instance_saves_during_initial_delivery_then_publishes_new_value() {
        // Given
        let otherStorage = GeneralAppSettingsStorage(fileStorage: fileStorage)
        var newSettings = GeneralAppSettings.default
        newSettings.knownCardReaders = ["READER2"]
        var receivedSettings = [GeneralAppSettings]()

        // When
        let cancelable = storage.settingsPublisher.sink { settings in
            receivedSettings.append(settings)
            if receivedSettings.count == 1 {
                do {
                    try otherStorage.saveSettings(newSettings)
                } catch {
                    XCTFail("Failed to save settings: \(error)")
                }
            }
        }
        defer { cancelable.cancel() }

        // Then
        XCTAssertEqual(receivedSettings, [GeneralAppSettings.default, newSettings])
    }

    func test_value_reads_settings_default_value() {
        // Given

        // When
        let value = storage.value(for: \.installationDate)

        // Then
        XCTAssertEqual(value, GeneralAppSettings.default.installationDate)
    }

    func test_setValue_saves_value() throws {
        // Given

        // When
        let date = Date()
        try storage.setValue(date, for: \.installationDate)

        // Then
        XCTAssertEqual(storage.value(for: \.installationDate), date)
    }

    func test_value_publisher_publishes_values() throws {
        // Given
        var receivedValues = [[String]]()

        let value1 = ["READER1"]
        let value2 = ["READER2"]
        try storage.setValue(value1, for: \.knownCardReaders)

        // When
        let cancelable = storage.publisher(for: \.knownCardReaders).sink { value in
            receivedValues.append(value)
        }
        try storage.setValue(value2, for: \.knownCardReaders)

        // Then
        XCTAssertEqual(receivedValues.count, 2)
        XCTAssertEqual(receivedValues, [value1, value2])

        // Tear down
        cancelable.cancel()
    }

    func test_value_publisher_does_not_publish_duplicates() throws {
        // Given
        var receivedValues = [[String]]()

        let value1 = ["READER1"]
        let value2 = ["READER1"]
        try storage.setValue(value1, for: \.knownCardReaders)
        let cancelable = storage.publisher(for: \.knownCardReaders).sink { value in
            receivedValues.append(value)
        }

        // When
        try storage.setValue(value2, for: \.knownCardReaders)

        // Then
        XCTAssertEqual(receivedValues.count, 1)
        XCTAssertEqual(receivedValues, [value1])

        // Tear down
        cancelable.cancel()
    }

    func test_value_publisher_does_not_publish_values_for_other_settings() throws {
        // Given
        var receivedValues = [[String]]()

        let value1 = ["READER1"]
        let value2 = Date()

        try storage.setValue(value1, for: \.knownCardReaders)
        let cancelable = storage.publisher(for: \.knownCardReaders).sink { value in
            receivedValues.append(value)
        }

        // When
        try storage.setValue(value2, for: \.installationDate)

        // Then
        XCTAssertEqual(receivedValues.count, 1)
        XCTAssertEqual(receivedValues, [value1])

        // Tear down
        cancelable.cancel()
    }
}
