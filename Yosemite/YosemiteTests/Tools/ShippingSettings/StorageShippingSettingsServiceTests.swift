import XCTest

@testable import Storage
@testable import Yosemite

final class StorageShippingSettingsServiceTests: XCTestCase {

    private let sampleSiteID = Int64(134)
    private var storage: CoreDataManager!

    override func setUp() {
        super.setUp()
        storage = CoreDataManager(name: "WooCommerce", crashLogger: MockCrashLogger())
    }

    override func tearDown() {
        storage = nil
        super.tearDown()
    }

    func testInitialShippingSettings() {
        let service = StorageShippingSettingsService(siteID: sampleSiteID, storageManager: storage)
        XCTAssertNil(service.dimensionUnit)
        XCTAssertNil(service.weightUnit)
    }

    func testDimensionUnit() {
        let expectedDimensionUnit = "km"
        insertDimensionUnitSiteSetting(value: expectedDimensionUnit, siteID: sampleSiteID)

        let service = StorageShippingSettingsService(siteID: sampleSiteID, storageManager: storage)

        XCTAssertEqual(service.dimensionUnit, expectedDimensionUnit)
    }

    func testWeightUnit() {
        let expectedWeightUnit = "kg"
        insertDimensionUnitSiteSetting(value: expectedWeightUnit, siteID: sampleSiteID)

        let service = StorageShippingSettingsService(siteID: sampleSiteID, storageManager: storage)

        XCTAssertEqual(service.dimensionUnit, expectedWeightUnit)
    }

    func testUpdatingSiteID() {
        let siteID1 = Int64(123)
        let expectedDimensionUnit1 = "km"
        insertDimensionUnitSiteSetting(value: expectedDimensionUnit1, siteID: siteID1)
        let expectedWeightUnit1 = "kg"
        insertWeightUnitSiteSetting(value: expectedWeightUnit1, siteID: siteID1)

        let service = StorageShippingSettingsService(siteID: siteID1, storageManager: storage)

        XCTAssertEqual(service.dimensionUnit, expectedDimensionUnit1)
        XCTAssertEqual(service.weightUnit, expectedWeightUnit1)

        let siteID2 = Int64(678)
        let expectedDimensionUnit2 = "in"
        insertDimensionUnitSiteSetting(value: expectedDimensionUnit2, siteID: siteID2)
        let expectedWeightUnit2 = "g"
        insertWeightUnitSiteSetting(value: expectedWeightUnit2, siteID: siteID2)

        service.update(siteID: siteID2)

        XCTAssertEqual(service.dimensionUnit, expectedDimensionUnit2)
        XCTAssertEqual(service.weightUnit, expectedWeightUnit2)
    }
}

private extension StorageShippingSettingsServiceTests {
    func insertDimensionUnitSiteSetting(value: String, siteID: Int64) {
        let siteSetting = storage.viewStorage.insertNewObject(ofType: SiteSetting.self)
        siteSetting.siteID = siteID
        siteSetting.settingGroupKey = SiteSettingGroup.product.rawValue
        siteSetting.settingID = "woocommerce_dimension_unit"
        siteSetting.value = value
    }

    func insertWeightUnitSiteSetting(value: String, siteID: Int64) {
        let siteSetting = storage.viewStorage.insertNewObject(ofType: SiteSetting.self)
        siteSetting.siteID = siteID
        siteSetting.settingGroupKey = SiteSettingGroup.product.rawValue
        siteSetting.settingID = "woocommerce_weight_unit"
        siteSetting.value = value
    }
}
