import XCTest
@testable import Yosemite
@testable import Storage

final class POSEligibilityServiceTests: XCTestCase {
    private var sut: POSEligibilityService!
    private var mockSiteSpecificAppSettingsStoreMethods: MockSiteSpecificAppSettingsStoreMethods!
    private let siteID: Int64 = 134

    override func setUp() {
        super.setUp()
        mockSiteSpecificAppSettingsStoreMethods = MockSiteSpecificAppSettingsStoreMethods()
        sut = POSEligibilityService(siteSpecificAppSettingsStoreMethods: mockSiteSpecificAppSettingsStoreMethods)
    }

    override func tearDown() {
        sut = nil
        mockSiteSpecificAppSettingsStoreMethods = nil
        super.tearDown()
    }

    func test_loadPOSTabVisibility_returns_nil_when_no_settings_exist() {
        // Given
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings()

        // When
        let result = sut.loadPOSTabVisibility(siteID: siteID)

        // Then
        XCTAssertNil(result)
    }

    func test_loadPOSTabVisibility_returns_stored_value_when_tab_is_visible() {
        // Given
        let storeSettings = GeneralStoreSettings(isPOSTabVisible: true, lastPOSTabVisibilityCheckDate: nil)
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = storeSettings

        // When
        let result = sut.loadPOSTabVisibility(siteID: siteID)

        // Then
        XCTAssertEqual(result, true)
    }

    func test_loadPOSTabVisibility_returns_false_when_tab_is_not_visible() {
        // Given
        let storeSettings = GeneralStoreSettings(isPOSTabVisible: false, lastPOSTabVisibilityCheckDate: nil)
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = storeSettings

        // When
        let result = sut.loadPOSTabVisibility(siteID: siteID)

        // Then
        XCTAssertEqual(result, false)
    }
}
