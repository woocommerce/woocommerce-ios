import Foundation
import Testing
@testable import Yosemite
import Storage

struct SiteSpecificAppSettingsStoreMethodsTests {
    private let fileStorage: MockFileStorage
    private let sut: SiteSpecificAppSettingsStoreMethods
    private let siteID: Int64 = 123

    init() {
        self.fileStorage = MockFileStorage()
        self.sut = SiteSpecificAppSettingsStoreMethods(fileStorage: fileStorage)
    }

    // MARK: - Store Settings Tests

    @Test func getStoreSettings_returns_default_settings_when_no_data_exists() {
        // When
        let settings = sut.getStoreSettings(for: siteID)

        // Then
        #expect(settings == GeneralStoreSettings())
    }

    @Test func getStoreSettings_returns_saved_settings_when_data_exists() throws {
        // Given
        let expectedSettings = GeneralStoreSettings(storeID: "test-store")
        let existingData = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: expectedSettings])
        try fileStorage.write(existingData, to: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)

        // When
        let settings = sut.getStoreSettings(for: siteID)

        // Then
        #expect(settings.storeID == expectedSettings.storeID)
    }

    @Test func setStoreSettings_saves_settings_successfully() async throws {
        // Given
        let settings = GeneralStoreSettings(storeID: "test-store")

        // When
        try await withCheckedThrowingContinuation { continuation in
            sut.setStoreSettings(settings: settings, for: siteID) { result in
                continuation.resume(with: result)
            }
        }

        // Then
        let savedData: GeneralStoreSettingsBySite = try fileStorage.data(for: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)
        #expect(savedData.storeSettingsBySite[siteID]?.storeID == settings.storeID)
    }

    @Test func setStoreSettings_preserves_existing_settings_for_other_sites() async throws {
        // Given
        let otherSiteID: Int64 = 456
        let otherSiteSettings = GeneralStoreSettings(storeID: "other-store")
        let existingData = GeneralStoreSettingsBySite(storeSettingsBySite: [otherSiteID: otherSiteSettings])
        try fileStorage.write(existingData, to: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)

        let newSettings = GeneralStoreSettings(storeID: "test-store")

        // When
        try await withCheckedThrowingContinuation { continuation in
            sut.setStoreSettings(settings: newSettings, for: siteID) { result in
                continuation.resume(with: result)
            }
        }

        // Then
        let savedData: GeneralStoreSettingsBySite = try fileStorage.data(for: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)
        #expect(savedData.storeSettingsBySite[siteID]?.storeID == newSettings.storeID)
        #expect(savedData.storeSettingsBySite[otherSiteID]?.storeID == otherSiteSettings.storeID)
    }

    @Test func resetStoreSettings_deletes_the_settings_file() throws {
        // Given
        let settings = GeneralStoreSettings(storeID: "test-store")
        try fileStorage.write(GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: settings]),
                              to: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)

        // When
        sut.resetStoreSettings()

        // Then
        #expect(fileStorage.deleteIsHit == true)
    }

    // MARK: - Store ID Tests

    @Test func setStoreID_updates_store_settings() throws {
        // Given
        let storeID = "test-store-id"
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: GeneralStoreSettings()])
        try fileStorage.write(existingSettings, to: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)

        // When
        sut.setStoreID(siteID: siteID, id: storeID)

        // Then
        let savedData: GeneralStoreSettingsBySite = try fileStorage.data(for: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)
        #expect(savedData.storeSettingsBySite[siteID]?.storeID == storeID)
    }

    @Test func getStoreID_retrieves_saved_store_id() throws {
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
        #expect(retrievedStoreID == storeID)
    }

    // MARK: - Search Terms Tests

    @Test func getSearchTerms_returns_empty_array_when_no_terms_exist() {
        // When
        let terms = sut.getSearchTerms(for: .product, siteID: siteID)

        // Then
        #expect(terms.isEmpty)
    }

    @Test func getSearchTerms_returns_saved_terms() throws {
        // Given
        let expectedTerms = ["term1", "term2", "term3"]
        let storeSettings = GeneralStoreSettings(searchTermsByKey: ["product_search_terms": expectedTerms])
        let existingData = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: storeSettings])
        try fileStorage.write(existingData, to: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)

        // When
        let terms = sut.getSearchTerms(for: .product, siteID: siteID)

        // Then
        #expect(terms == expectedTerms)
    }

    @Test func setSearchTerms_saves_terms_successfully() throws {
        // Given
        let terms = ["term1", "term2", "term3"]
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: GeneralStoreSettings()])
        try fileStorage.write(existingSettings, to: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)

        // When
        sut.setSearchTerms(terms, for: .product, siteID: siteID)

        // Then
        let savedData: GeneralStoreSettingsBySite = try fileStorage.data(for: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)
        #expect(savedData.storeSettingsBySite[siteID]?.searchTermsByKey["product_search_terms"] == terms)
    }

    @Test func setSearchTerms_preserves_existing_terms_for_other_item_types() throws {
        // Given
        let existingTerms = ["existing1", "existing2"]
        let storeSettings = GeneralStoreSettings(searchTermsByKey: ["variation_search_terms": existingTerms])
        let existingData = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: storeSettings])
        try fileStorage.write(existingData, to: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)

        let newTerms = ["new1", "new2"]
        sut.setSearchTerms(newTerms, for: .product, siteID: siteID)

        // Then
        let savedData: GeneralStoreSettingsBySite = try fileStorage.data(for: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)
        #expect(savedData.storeSettingsBySite[siteID]?.searchTermsByKey["product_search_terms"] == newTerms)
        #expect(savedData.storeSettingsBySite[siteID]?.searchTermsByKey["variation_search_terms"] == existingTerms)
    }

    @Test func setSearchTerms_preserves_existing_terms_for_other_sites() throws {
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
        #expect(savedData.storeSettingsBySite[siteID]?.searchTermsByKey["product_search_terms"] == newTerms)
        #expect(savedData.storeSettingsBySite[otherSiteID]?.searchTermsByKey["product_search_terms"] == otherSiteTerms)
    }

    @Test func resetStoreSettings_clears_search_terms() throws {
        // Given
        let terms = ["term1", "term2"]
        let storeSettings = GeneralStoreSettings(searchTermsByKey: ["product_search_terms": terms])
        let existingData = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: storeSettings])
        try fileStorage.write(existingData, to: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)

        // When
        sut.resetStoreSettings()

        // Then
        #expect(fileStorage.deleteIsHit == true)
        let savedTerms = sut.getSearchTerms(for: .product, siteID: siteID)
        #expect(savedTerms.isEmpty)
    }

    @Test func search_terms_work_for_all_item_types() throws {
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
        #expect(retrievedProductTerms == productTerms)
        #expect(retrievedVariationTerms == variationTerms)
        #expect(retrievedCouponTerms == couponTerms)
    }

    // MARK: - POS Local Catalog Cellular Data Tests

    @Test func getPOSLocalCatalogCellularDataAllowed_returns_true_by_default() {
        // When
        let isAllowed = sut.getPOSLocalCatalogCellularDataAllowed(siteID: siteID)

        // Then
        #expect(isAllowed == true)
    }

    @Test func getPOSLocalCatalogCellularDataAllowed_returns_saved_value() throws {
        // Given
        let storeSettings = GeneralStoreSettings(syncPOSCatalogOverCellular: false)
        let existingData = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: storeSettings])
        try fileStorage.write(existingData, to: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)

        // When
        let isAllowed = sut.getPOSLocalCatalogCellularDataAllowed(siteID: siteID)

        // Then
        #expect(isAllowed == false)
    }

    @Test func setPOSLocalCatalogCellularDataAllowed_saves_value_successfully() throws {
        // Given
        let existingSettings = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: GeneralStoreSettings()])
        try fileStorage.write(existingSettings, to: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)

        // When
        sut.setPOSLocalCatalogCellularDataAllowed(siteID: siteID, allowed: false)

        // Then
        let savedData: GeneralStoreSettingsBySite = try fileStorage.data(for: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)
        #expect(savedData.storeSettingsBySite[siteID]?.syncPOSCatalogOverCellular == false)
    }

    @Test func setPOSLocalCatalogCellularDataAllowed_preserves_existing_settings() throws {
        // Given
        let existingStoreID = "existing-store-id"
        let existingSettings = GeneralStoreSettings(storeID: existingStoreID)
        let existingData = GeneralStoreSettingsBySite(storeSettingsBySite: [siteID: existingSettings])
        try fileStorage.write(existingData, to: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)

        // When
        sut.setPOSLocalCatalogCellularDataAllowed(siteID: siteID, allowed: false)

        // Then
        let savedData: GeneralStoreSettingsBySite = try fileStorage.data(for: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)
        #expect(savedData.storeSettingsBySite[siteID]?.syncPOSCatalogOverCellular == false)
        #expect(savedData.storeSettingsBySite[siteID]?.storeID == existingStoreID)
    }

    @Test func setPOSLocalCatalogCellularDataAllowed_preserves_settings_for_other_sites() throws {
        // Given
        let otherSiteID: Int64 = 456
        let otherSiteSettings = GeneralStoreSettings(syncPOSCatalogOverCellular: true)
        let existingData = GeneralStoreSettingsBySite(storeSettingsBySite: [otherSiteID: otherSiteSettings])
        try fileStorage.write(existingData, to: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)

        // When
        sut.setPOSLocalCatalogCellularDataAllowed(siteID: siteID, allowed: false)

        // Then
        let savedData: GeneralStoreSettingsBySite = try fileStorage.data(for: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)
        #expect(savedData.storeSettingsBySite[siteID]?.syncPOSCatalogOverCellular == false)
        #expect(savedData.storeSettingsBySite[otherSiteID]?.syncPOSCatalogOverCellular == true)
    }

    // MARK: - Sunset Warning Tests

    @Test func getSunsetWarningLastShownDate_returns_nil_when_no_date_set() {
        // When
        let date = sut.getSunsetWarningLastShownDate(siteID: siteID)

        // Then
        #expect(date == nil)
    }

    @Test func setSunsetWarningLastShownDate_persists_date() throws {
        // Given
        let expectedDate = Date()

        // When
        sut.setSunsetWarningLastShownDate(siteID: siteID, date: expectedDate)

        // Then
        let savedData: GeneralStoreSettingsBySite = try fileStorage.data(for: SiteSpecificAppSettingsStoreMethods.defaultGeneralStoreSettingsFileURL)
        #expect(savedData.storeSettingsBySite[siteID]?.lastSunsetWarningShownDate == expectedDate)
    }

    @Test func getSunsetWarningLastShownDate_returns_persisted_date() {
        // Given
        let expectedDate = Date()
        sut.setSunsetWarningLastShownDate(siteID: siteID, date: expectedDate)

        // When
        let date = sut.getSunsetWarningLastShownDate(siteID: siteID)

        // Then
        #expect(date == expectedDate)
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
