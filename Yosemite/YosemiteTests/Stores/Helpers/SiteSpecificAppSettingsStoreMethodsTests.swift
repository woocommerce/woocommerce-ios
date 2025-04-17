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

    // MARK: - Search Terms Tests

    func test_getSearchTerms_returns_empty_array_when_no_terms_exist() {
        // When
        let terms = sut.getSearchTerms(for: .product, siteID: siteID)

        // Then
        XCTAssertTrue(terms.isEmpty)
    }

    func test_getSearchTerms_returns_saved_terms() throws {
        // Given
        let expectedTerms = ["term1", "term2", "term3"]
        let storeSettings = GeneralStoreSettings(searchTermsByKey: ["product_search_terms": expectedTerms])
        let existingData = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: storeSettings])
        try fileStorage.write(existingData, to: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)

        // When
        let terms = sut.getSearchTerms(for: .product, siteID: siteID)

        // Then
        XCTAssertEqual(terms, expectedTerms)
    }

    func test_setSearchTerms_saves_terms_successfully() throws {
        // Given
        let terms = ["term1", "term2", "term3"]
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: GeneralStoreSettings()])
        try fileStorage.write(existingSettings, to: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)

        // When
        sut.setSearchTerms(terms, for: .product, siteID: siteID)

        // Then
        let savedData: GeneralStoreSettingsBySite = try fileStorage.data(for: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)
        XCTAssertEqual(savedData.storeSettingsBySite[siteID]?.searchTermsByKey["product_search_terms"], terms)
    }

    func test_setSearchTerms_preserves_existing_terms_for_other_item_types() throws {
        // Given
        let existingTerms = ["existing1", "existing2"]
        let storeSettings = GeneralStoreSettings(searchTermsByKey: ["variation_search_terms": existingTerms])
        let existingData = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: storeSettings])
        try fileStorage.write(existingData, to: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)

        let newTerms = ["new1", "new2"]
        sut.setSearchTerms(newTerms, for: .product, siteID: siteID)

        // Then
        let savedData: GeneralStoreSettingsBySite = try fileStorage.data(for: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)
        XCTAssertEqual(savedData.storeSettingsBySite[siteID]?.searchTermsByKey["product_search_terms"], newTerms)
        XCTAssertEqual(savedData.storeSettingsBySite[siteID]?.searchTermsByKey["variation_search_terms"], existingTerms)
    }

    func test_setSearchTerms_preserves_existing_terms_for_other_sites() throws {
        // Given
        let otherSiteID: Int64 = 456
        let otherSiteTerms = ["other1", "other2"]
        let storeSettings = GeneralStoreSettings(searchTermsByKey: ["product_search_terms": otherSiteTerms])
        let existingData = GeneralStoreSettingsBySite(storeSettingsBySite: [otherSiteID: storeSettings])
        try fileStorage.write(existingData, to: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)

        let newTerms = ["new1", "new2"]
        sut.setSearchTerms(newTerms, for: .product, siteID: siteID)

        // Then
        let savedData: GeneralStoreSettingsBySite = try fileStorage.data(for: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)
        XCTAssertEqual(savedData.storeSettingsBySite[siteID]?.searchTermsByKey["product_search_terms"], newTerms)
        XCTAssertEqual(savedData.storeSettingsBySite[otherSiteID]?.searchTermsByKey["product_search_terms"], otherSiteTerms)
    }

    func test_resetStoreSettings_clears_search_terms() throws {
        // Given
        let terms = ["term1", "term2"]
        let storeSettings = GeneralStoreSettings(searchTermsByKey: ["product_search_terms": terms])
        let existingData = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: storeSettings])
        try fileStorage.write(existingData, to: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)

        // When
        sut.resetStoreSettings()

        // Then
        XCTAssertTrue(fileStorage.deleteIsHit)
        let savedTerms = sut.getSearchTerms(for: .product, siteID: siteID)
        XCTAssertTrue(savedTerms.isEmpty)
    }

    func test_search_terms_work_for_all_item_types() throws {
        // Given
        let productTerms = ["product1", "product2"]
        let variationTerms = ["variation1", "variation2"]
        let couponTerms = ["coupon1", "coupon2"]
        let storeSettings = GeneralStoreSettings(searchTermsByKey: [
            "product_search_terms": productTerms,
            "variation_search_terms": variationTerms,
            "coupon_search_terms": couponTerms
        ])
        let existingData = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: storeSettings])
        try fileStorage.write(existingData, to: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)

        // When
        let retrievedProductTerms = sut.getSearchTerms(for: .product, siteID: siteID)
        let retrievedVariationTerms = sut.getSearchTerms(for: .variation, siteID: siteID)
        let retrievedCouponTerms = sut.getSearchTerms(for: .coupon, siteID: siteID)

        // Then
        XCTAssertEqual(retrievedProductTerms, productTerms)
        XCTAssertEqual(retrievedVariationTerms, variationTerms)
        XCTAssertEqual(retrievedCouponTerms, couponTerms)
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
