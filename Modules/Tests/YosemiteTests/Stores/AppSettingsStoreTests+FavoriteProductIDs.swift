import Foundation
import XCTest
@testable import Yosemite
@testable import Storage

final class AppSettingsStoreTests_FavoriteProductIDs: XCTestCase {
    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock File Storage: Load data in memory
    ///
    private var fileStorage: MockInMemoryStorage!

    /// Mock General Settings Storage: Load data in memory
    ///
    private var generalAppSettings: GeneralAppSettingsStorage!

    /// Test subject
    ///
    private var subject: AppSettingsStore!

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        fileStorage = MockInMemoryStorage()
        generalAppSettings = GeneralAppSettingsStorage(fileStorage: fileStorage)
        subject = AppSettingsStore(dispatcher: dispatcher!, storageManager: storageManager!, fileStorage: fileStorage!, generalAppSettings: generalAppSettings!)
    }

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        fileStorage = nil
        generalAppSettings = nil
        subject = nil
        super.tearDown()
    }

    func test_setProductIDAsFavorite_stores_the_value() throws {
        // Given
        let siteID: Int64 = 1234
        let favProductID: Int64 = 4321

        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: GeneralStoreSettings(favoriteProductIDs: [])])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        let action = AppSettingsAction.setProductIDAsFavorite(productID: favProductID, siteID: siteID)
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralStoreSettingsBySite = try XCTUnwrap(fileStorage?.data(for: expectedGeneralStoreSettingsFileURL))
        let settingsForSite = savedSettings.storeSettingsBySite[siteID]

        XCTAssertEqual([favProductID], settingsForSite?.favoriteProductIDs)
    }

    func test_removeProductIDAsFavorite_the_value() throws {
        // Given
        let siteID: Int64 = 1234
        let favProductID: Int64 = 4321

        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: GeneralStoreSettings(favoriteProductIDs: [favProductID])])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        let action = AppSettingsAction.removeProductIDAsFavorite(productID: favProductID, siteID: siteID)
        subject?.onAction(action)

        // Then
        let savedSettings: GeneralStoreSettingsBySite = try XCTUnwrap(fileStorage?.data(for: expectedGeneralStoreSettingsFileURL))
        let settingsForSite = savedSettings.storeSettingsBySite[siteID]

        XCTAssertNil(settingsForSite?.selectedTaxRateID)
    }

    func test_loadFavoriteProductIDs_works_correctly() throws {
        // Given
        let siteID: Int64 = 1234
        let storedFavProductID: Int64 = 4321

        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: GeneralStoreSettings(favoriteProductIDs: [storedFavProductID])])
        try fileStorage?.write(existingSettings, to: expectedGeneralStoreSettingsFileURL)

        // When
        var loadedFavProductID: [Int64]?
        let action = AppSettingsAction.loadFavoriteProductIDs(siteID: siteID) { favIDs in
            loadedFavProductID = favIDs
        }
        subject?.onAction(action)

        // Then
        XCTAssertEqual(loadedFavProductID, [storedFavProductID])
    }

    var expectedGeneralStoreSettingsFileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent("general-store-settings.plist")
    }
}
