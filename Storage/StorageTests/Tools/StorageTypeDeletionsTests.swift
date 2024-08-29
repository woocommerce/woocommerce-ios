import XCTest
@testable import Storage
@testable import WooFoundation

final class StorageTypeDeletionsTests: XCTestCase {

    private let sampleSiteID: Int64 = 98765
    private var storageManager: StorageManagerType!

    private var storage: StorageType! {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = CoreDataManager(name: "WooCommerce", crashLogger: MockCrashLogger())
    }

    override func tearDown() {
        storageManager.reset()
        storageManager = nil
        super.tearDown()
    }

    func test_deleteCoupon_by_siteID_deletes_all_coupons() throws {
        // Given
        let coupon1 = storage.insertNewObject(ofType: Coupon.self)
        coupon1.siteID = sampleSiteID
        coupon1.couponID = 1

        let coupon2 = storage.insertNewObject(ofType: Coupon.self)
        coupon2.siteID = sampleSiteID
        coupon2.couponID = 2

        XCTAssertEqual(storage.loadAllCoupons(siteID: sampleSiteID).count, 2)

        // When
        storage.deleteCoupons(siteID: sampleSiteID)

        // Then
        let storedCoupons = try XCTUnwrap(storage.loadAllCoupons(siteID: sampleSiteID))
        XCTAssertEqual(storedCoupons, [])
    }

    func test_deleteCoupon_by_siteID_only_deletes_for_specified_site() throws {
        // Given
        let coupon = storage.insertNewObject(ofType: Coupon.self)
        coupon.siteID = sampleSiteID
        coupon.couponID = 1

        let otherSiteCoupon = storage.insertNewObject(ofType: Coupon.self)
        otherSiteCoupon.siteID = 12345
        otherSiteCoupon.couponID = 2

        // When
        storage.deleteCoupons(siteID: sampleSiteID)

        // Then
        let storedCoupons = try XCTUnwrap(storage.loadAllCoupons(siteID: 12345))
        XCTAssertEqual(storedCoupons, [otherSiteCoupon])
    }

    func test_deleteCoupon_by_siteID_and_couponID_only_deletes_coupon_with_the_given_IDs() throws {
        // Given
        let sampleCouponID: Int64 = 13435
        let coupon = storage.insertNewObject(ofType: Coupon.self)
        coupon.siteID = sampleSiteID
        coupon.couponID = sampleCouponID

        let otherCoupon = storage.insertNewObject(ofType: Coupon.self)
        otherCoupon.siteID = sampleSiteID
        otherCoupon.couponID = 2

        // When
        storage.deleteCoupon(siteID: sampleSiteID, couponID: sampleCouponID)

        // Then
        let storedCoupons = try XCTUnwrap(storage.loadAllCoupons(siteID: sampleSiteID))
        XCTAssertEqual(storedCoupons, [otherCoupon])
    }

    func test_deleteCoupon_by_siteID_and_couponID_only_deletes_coupon_for_the_given_site() throws {
        // Given
        let sampleCouponID: Int64 = 13435
        let coupon = storage.insertNewObject(ofType: Coupon.self)
        coupon.siteID = sampleSiteID
        coupon.couponID = sampleCouponID

        let otherSiteID: Int64 = 333
        let otherCoupon = storage.insertNewObject(ofType: Coupon.self)
        otherCoupon.siteID = otherSiteID
        otherCoupon.couponID = sampleCouponID

        // When
        storage.deleteCoupon(siteID: sampleSiteID, couponID: sampleCouponID)

        // Then
        let storedCoupons = try XCTUnwrap(storage.loadAllCoupons(siteID: otherSiteID))
        XCTAssertEqual(storedCoupons, [otherCoupon])
    }

    func test_deleteStaleAddOnGroups_does_not_delete_active_addOns() throws {
        // Given
        let initialGroups: [AddOnGroup] = [
            createAddOnGroup(groupID: 123, name: "AAA"),
            createAddOnGroup(groupID: 1234, name: "BBB"),
            createAddOnGroup(groupID: 12345, name: "CCC")
        ]

        // When
        storage.deleteStaleAddOnGroups(siteID: sampleSiteID, activeGroupIDs: [123, 1234])

        // Then
        let activeGroups = storage.loadAddOnGroups(siteID: sampleSiteID)
        XCTAssertEqual(activeGroups, initialGroups.dropLast())
    }

    func test_deleteStalePlugins_deletes_plugins_not_included_in_installedPluginNames() throws {
        // Given
        let plugin1 = createPlugin(name: "AAA")
        _ = createPlugin(name: "BBB")
        let plugin3 = createPlugin(name: "CCC")

        // When
        storage.deleteStalePlugins(siteID: sampleSiteID, installedPluginNames: ["AAA", "CCC"])

        // Then
        let currentPlugins = storage.loadPlugins(siteID: sampleSiteID)
        XCTAssertEqual(currentPlugins, [plugin1, plugin3])
    }

    // MARK: - System plugins

    func test_deleteStaleSystemPlugins_deletes_systemPlugins_not_included_in_currentSystemPlugins() throws {
        // Given
        _ = createSystemPlugin(name: "Plugin 1")
        _ = createSystemPlugin(name: "Plugin 2")
        let systemPlugin3 = createSystemPlugin(name: "Plugin 3")

        // When
        storage.deleteStaleSystemPlugins(siteID: sampleSiteID, currentSystemPlugins: ["Plugin 3"])

        // Then
        let currrentSystemPlugin = storage.loadSystemPlugins(siteID: sampleSiteID)
        XCTAssertEqual(currrentSystemPlugin, [systemPlugin3])
    }

    func test_deleteBlazeTargetDevices_with_locale() throws {
        // Given
        let device1 = storage.insertNewObject(ofType: BlazeTargetDevice.self)
        device1.id = "mobile"
        device1.name = "Mobile"
        device1.locale = "en"

        let device2 = storage.insertNewObject(ofType: BlazeTargetDevice.self)
        device2.id = "desktop"
        device2.name = "Desktop"
        device2.locale = "es"

        // When
        storage.deleteBlazeTargetDevices(locale: "en")

        // Then
        let enDevices = storage.loadAllBlazeTargetDevices(locale: "en")
        XCTAssertTrue(enDevices.isEmpty)
        let esDevices = storage.loadAllBlazeTargetDevices(locale: "es")
        XCTAssertEqual(esDevices.count, 1)
    }

    func test_deleteBlazeTargetLanguages_with_locale() throws {
        // Given
        let language1 = storage.insertNewObject(ofType: BlazeTargetLanguage.self)
        language1.id = "en"
        language1.name = "English"
        language1.locale = "en"

        let language2 = storage.insertNewObject(ofType: BlazeTargetLanguage.self)
        language2.id = "en"
        language2.name = "Tiếng Anh"
        language2.locale = "vi"

        // When
        storage.deleteBlazeTargetLanguages(locale: "en")

        // Then
        let enLanguages = storage.loadAllBlazeTargetLanguages(locale: "en")
        XCTAssertTrue(enLanguages.isEmpty)
        let viLanguages = storage.loadAllBlazeTargetLanguages(locale: "vi")
        XCTAssertEqual(viLanguages.count, 1)
    }

    func test_deleteBlazeTargetTopics_with_locale() throws {
        // Given
        let topic1 = storage.insertNewObject(ofType: BlazeTargetTopic.self)
        topic1.id = "1"
        topic1.name = "Cuisines"
        topic1.locale = "en"

        let topic2 = storage.insertNewObject(ofType: BlazeTargetTopic.self)
        topic2.id = "1"
        topic2.name = "Ẩm thực"
        topic2.locale = "vi"

        // When
        storage.deleteBlazeTargetTopics(locale: "en")

        // Then
        let enTopics = storage.loadAllBlazeTargetTopics(locale: "en")
        XCTAssertTrue(enTopics.isEmpty)
        let viTopics = storage.loadAllBlazeTargetTopics(locale: "vi")
        XCTAssertEqual(viTopics.count, 1)
    }

    func test_deleteBlazeCampaignObjectives_with_locale() throws {
        // Given
        let objective1 = storage.insertNewObject(ofType: BlazeCampaignObjective.self)
        objective1.id = "sale"
        objective1.title = "Sale"
        objective1.generalDescription = "Lorem ipsum"
        objective1.suitableForDescription = "e-commerce"
        objective1.locale = "en"

        let objective2 = storage.insertNewObject(ofType: BlazeCampaignObjective.self)
        objective2.id = "sale"
        objective2.title = "doanh thu"
        objective2.generalDescription = "la la la"
        objective2.suitableForDescription = "thương mại điện tử"
        objective2.locale = "vi"

        // When
        storage.deleteBlazeCampaignObjectives(locale: "en")

        // Then
        let enTopics = storage.loadAllBlazeCampaignObjectives(locale: "en")
        XCTAssertTrue(enTopics.isEmpty)
        let viTopics = storage.loadAllBlazeCampaignObjectives(locale: "vi")
        XCTAssertEqual(viTopics.count, 1)
    }
}

private extension StorageTypeDeletionsTests {
    /// Inserts and creates an `AddOnGroup` ready to be used on tests.
    ///
    func createAddOnGroup(groupID: Int64, name: String) -> AddOnGroup {
        let addOnGroup = storage.insertNewObject(ofType: AddOnGroup.self)
        addOnGroup.siteID = sampleSiteID
        addOnGroup.groupID = groupID
        addOnGroup.name = name
        return addOnGroup
    }

    /// Creates and inserts a `SitePlugin` entity with a given name
    ///
    func createPlugin(name: String) -> SitePlugin {
        let plugin = storage.insertNewObject(ofType: SitePlugin.self)
        plugin.siteID = sampleSiteID
        plugin.name = name
        return plugin
    }

    /// Creates and inserts a `SystemPlugin` entity with a given name
    ///
    func createSystemPlugin(name: String) -> SystemPlugin {
        let systemPlugin = storage.insertNewObject(ofType: SystemPlugin.self)
        systemPlugin.siteID = sampleSiteID
        systemPlugin.name = name
        return systemPlugin
    }
}
