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
        let currentDate = Date(timeIntervalSince1970: 1750054337)
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = GeneralStoreSettings()

        // When
        let result = sut.loadPOSTabVisibility(siteID: siteID, currentDate: currentDate)

        // Then
        XCTAssertNil(result)
    }

    func test_loadPOSTabVisibility_returns_nil_when_last_check_date_is_older_than_3_days() {
        // Given
        let currentDate = Date(timeIntervalSince1970: 1750054337)
        let oldDate = currentDate.addingTimeInterval(-3 * 24 * 60 * 60 - 1) // 3 days and 1 second ago
        let storeSettings = GeneralStoreSettings(isPOSTabVisible: true, lastPOSTabVisibilityCheckDate: oldDate)
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = storeSettings

        // When
        let result = sut.loadPOSTabVisibility(siteID: siteID, currentDate: currentDate)

        // Then
        XCTAssertNil(result)
    }

    func test_loadPOSTabVisibility_returns_stored_value_when_last_check_date_is_within_3_days() {
        // Given
        let currentDate = Date(timeIntervalSince1970: 1750054337)
        let recentDate = currentDate.addingTimeInterval(-3 * 24 * 60 * 60 + 1) // 1 second before 3 days ago
        let storeSettings = GeneralStoreSettings(isPOSTabVisible: true, lastPOSTabVisibilityCheckDate: recentDate)
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = storeSettings

        // When
        let result = sut.loadPOSTabVisibility(siteID: siteID, currentDate: currentDate)

        // Then
        XCTAssertEqual(result, true)
    }

    func test_loadPOSTabVisibility_returns_nil_when_no_last_check_date() {
        // Given
        let currentDate = Date(timeIntervalSince1970: 1750054337)
        let storeSettings = GeneralStoreSettings(isPOSTabVisible: true, lastPOSTabVisibilityCheckDate: nil)
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = storeSettings

        // When
        let result = sut.loadPOSTabVisibility(siteID: siteID, currentDate: currentDate)

        // Then
        XCTAssertNil(result)
    }

    func test_loadPOSTabVisibility_returns_false_when_tab_is_not_visible() {
        // Given
        let currentDate = Date(timeIntervalSince1970: 1750054337)
        let recentDate = currentDate.addingTimeInterval(-1 * 24 * 60 * 60) // 1 day ago
        let storeSettings = GeneralStoreSettings(isPOSTabVisible: false, lastPOSTabVisibilityCheckDate: recentDate)
        mockSiteSpecificAppSettingsStoreMethods.storeSettings = storeSettings

        // When
        let result = sut.loadPOSTabVisibility(siteID: siteID, currentDate: currentDate)

        // Then
        XCTAssertEqual(result, false)
    }
}
