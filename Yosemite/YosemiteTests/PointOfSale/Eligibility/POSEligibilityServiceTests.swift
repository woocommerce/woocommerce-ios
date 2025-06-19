import Testing
@testable import Yosemite
@testable import Storage

struct POSEligibilityServiceTests {
    private var sut: POSEligibilityService!
    private var mockSiteSpecificAppSettingsStoreMethods: MockSiteSpecificAppSettingsStoreMethods!
    private let siteID: Int64 = 134

    init() {
        mockSiteSpecificAppSettingsStoreMethods = MockSiteSpecificAppSettingsStoreMethods()
        mockSiteSpecificAppSettingsStoreMethods.currentSiteID = siteID
        sut = POSEligibilityService(siteSpecificAppSettingsStoreMethods: mockSiteSpecificAppSettingsStoreMethods)
    }

    @Test func loadCachedPOSTabVisibility_returns_nil_when_no_settings_exist() {
        // Given
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings()

        // When
        let result = sut.loadCachedPOSTabVisibility(siteID: siteID)

        // Then
        #expect(result == nil)
    }

    @Test func loadCachedPOSTabVisibility_returns_stored_value_when_tab_is_visible() {
        // Given
        let storeSettings = GeneralStoreSettings(isPOSTabVisible: true)
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = storeSettings

        // When
        let result = sut.loadCachedPOSTabVisibility(siteID: siteID)

        // Then
        #expect(result == true)
    }

    @Test func loadCachedPOSTabVisibility_returns_false_when_tab_is_not_visible() {
        // Given
        let storeSettings = GeneralStoreSettings(isPOSTabVisible: false)
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = storeSettings

        // When
        let result = sut.loadCachedPOSTabVisibility(siteID: siteID)

        // Then
        #expect(result == false)
    }

    // MARK: - cachePOSTabVisibility Tests

    @Test func cachePOSTabVisibility_updates_isPOSTabVisible_to_true() {
        // Given
        let initialSettings = GeneralStoreSettings(isPOSTabVisible: false)
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = initialSettings

        // When
        sut.cachePOSTabVisibility(siteID: siteID, isVisible: true)

        // Then
        #expect(mockSiteSpecificAppSettingsStoreMethods.setStoreSettingsCalled == true)
        let updatedSettings = mockSiteSpecificAppSettingsStoreMethods.storeSettings
        #expect(updatedSettings.isPOSTabVisible == true)
    }

    @Test func cachePOSTabVisibility_updates_isPOSTabVisible_to_false() {
        // Given
        let initialSettings = GeneralStoreSettings(isPOSTabVisible: true)
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = initialSettings

        // When
        sut.cachePOSTabVisibility(siteID: siteID, isVisible: false)

        // Then
        #expect(mockSiteSpecificAppSettingsStoreMethods.setStoreSettingsCalled == true)
        let updatedSettings = mockSiteSpecificAppSettingsStoreMethods.storeSettings
        #expect(updatedSettings.isPOSTabVisible == false)
    }

    @Test func cachePOSTabVisibility_preserves_other_settings() {
        // Given
        let initialSettings = GeneralStoreSettings(
            storeID: "test-store",
            favoriteProductIDs: [1, 2, 3],
            isPOSTabVisible: false,
        )
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = initialSettings

        // When
        sut.cachePOSTabVisibility(siteID: siteID, isVisible: true)

        // Then
        let updatedSettings = mockSiteSpecificAppSettingsStoreMethods.storeSettings
        #expect(updatedSettings.isPOSTabVisible == true)
        #expect(updatedSettings.storeID == "test-store")
        #expect(updatedSettings.favoriteProductIDs == [1, 2, 3])
    }
}
