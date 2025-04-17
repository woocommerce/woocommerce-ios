import XCTest
@testable import Yosemite
import Storage

final class SiteSpecificAppSettingsStoreMethodsTests: XCTestCase {
    private var sut: SiteSpecificAppSettingsStoreMethods!
    private var fileStorage: MockFileStorage!
    private let siteID: Int64 = 123

    override func setUp() {
        super.setUp()
        fileStorage = MockFileStorage()
        sut = SiteSpecificAppSettingsStoreMethods(fileStorage: fileStorage)
    }

    override func tearDown() {
        sut = nil
        fileStorage = nil
        super.tearDown()
    }

    // MARK: - Store Settings Tests

    func test_getStoreSettings_returns_default_settings_when_no_data_exists() {
        // When
        let settings = sut.getStoreSettings(for: siteID)

        // Then
        XCTAssertEqual(settings, GeneralStoreSettings())
    }

    func test_getStoreSettings_returns_saved_settings_when_data_exists() throws {
        // Given
        let expectedSettings = GeneralStoreSettings(storeID: "test-store")
        let existingData = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: expectedSettings])
        try fileStorage.write(existingData, to: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)

        // When
        let settings = sut.getStoreSettings(for: siteID)

        // Then
        XCTAssertEqual(settings.storeID, expectedSettings.storeID)
    }

    func test_setStoreSettings_saves_settings_successfully() throws {
        // Given
        let settings = GeneralStoreSettings(storeID: "test-store")
        let expectation = self.expectation(description: "Settings saved")

        // When
        sut.setStoreSettings(settings: settings, for: siteID) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success but got failure")
            }
        }

        // Then
        wait(for: [expectation], timeout: 1)
        let savedData: GeneralStoreSettingsBySite = try fileStorage.data(for: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)
        XCTAssertEqual(savedData.storeSettingsBySite[siteID]?.storeID, settings.storeID)
    }

    func test_setStoreSettings_preserves_existing_settings_for_other_sites() throws {
        // Given
        let otherSiteID: Int64 = 456
        let otherSiteSettings = GeneralStoreSettings(storeID: "other-store")
        let existingData = GeneralStoreSettingsBySite(storeSettingsBySite: [otherSiteID: otherSiteSettings])
        try fileStorage.write(existingData, to: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)

        let newSettings = GeneralStoreSettings(storeID: "test-store")
        let expectation = self.expectation(description: "Settings saved")

        // When
        sut.setStoreSettings(settings: newSettings, for: siteID) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success but got failure")
            }
        }

        // Then
        wait(for: [expectation], timeout: 1)
        let savedData: GeneralStoreSettingsBySite = try fileStorage.data(for: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)
        XCTAssertEqual(savedData.storeSettingsBySite[siteID]?.storeID, newSettings.storeID)
        XCTAssertEqual(savedData.storeSettingsBySite[otherSiteID]?.storeID, otherSiteSettings.storeID)
    }

    func test_resetStoreSettings_deletes_the_settings_file() throws {
        // Given
        let settings = GeneralStoreSettings(storeID: "test-store")
        try fileStorage.write(GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: settings]),
                            to: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)

        // When
        sut.resetStoreSettings()

        // Then
        XCTAssertTrue(fileStorage.deleteIsHit)
    }

    // MARK: - Store ID Tests

    func test_setStoreID_updates_store_settings() throws {
        // Given
        let storeID = "test-store-id"
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: GeneralStoreSettings()])
        try fileStorage.write(existingSettings, to: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)

        // When
        sut.setStoreID(siteID: siteID, id: storeID)

        // Then
        let savedData: GeneralStoreSettingsBySite = try fileStorage.data(for: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)
        XCTAssertEqual(savedData.storeSettingsBySite[siteID]?.storeID, storeID)
    }

    func test_getStoreID_retrieves_saved_store_id() throws {
        // Given
        let storeID = "test-store-id"
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: GeneralStoreSettings(storeID: storeID)])
        try fileStorage.write(existingSettings, to: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)

        // When
        var retrievedStoreID: String?
        sut.getStoreID(siteID: siteID) { id in
            retrievedStoreID = id
        }

        // Then
        XCTAssertEqual(retrievedStoreID, storeID)
    }
}

// MARK: - Mock FileStorage

private class MockFileStorage: FileStorage {
    var data: [URL: Any] = [:]
    var dataWriteIsHit = false
    var deleteIsHit = false

    func data<T>(for url: URL) throws -> T where T: Decodable {
        guard let data = data[url] as? T else {
            throw AppSettingsStoreErrors.readPListFromFileStorage
        }
        return data
    }

    func write<T>(_ data: T, to url: URL) throws where T: Encodable {
        self.data[url] = data
        dataWriteIsHit = true
    }

    func deleteFile(at url: URL) throws {
        data.removeValue(forKey: url)
        deleteIsHit = true
    }
}
