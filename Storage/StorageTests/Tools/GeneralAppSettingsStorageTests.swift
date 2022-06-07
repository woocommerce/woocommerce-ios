import XCTest
import Storage

class GeneralAppSettingsStorageTests: XCTestCase {
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
}
