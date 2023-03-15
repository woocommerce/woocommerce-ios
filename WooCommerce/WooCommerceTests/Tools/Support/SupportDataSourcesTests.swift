import XCTest
@testable import WooCommerce

final class SupportDataSourcesTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        ServiceLocator.setFeatureFlagService(MockFeatureFlagService(isSupportRequestEnabled: true))
    }

    func test_mobile_app_formID_has_correct_value() {
        let dataSource = MobileAppSupportDataSource(metadataProvider: SupportFormMetadataProvider())
        XCTAssertEqual(dataSource.formID, 360000010286)
    }

    func test_mobile_app_tags_have_correct_values() {
        // Given
        let dataSource = MobileAppSupportDataSource(metadataProvider: SupportFormMetadataProvider())
        let tagsSet = Set(dataSource.tags)
        let expectedSet = Set(["iOS", "jetpack", "woocommerce_mobile_apps"])

        // When & Then
        XCTAssertTrue(expectedSet.isSubset(of: tagsSet))
    }

    func test_mobile_app_fields_have_correct_ids() {
        let dataSource = MobileAppSupportDataSource(metadataProvider: SupportFormMetadataProvider())
        let customFieldsKeys = dataSource.customFields.keys.sorted()
        XCTAssertEqual(customFieldsKeys, [
            360008583691, // App Language
            360000103103, // Current Site
            360009311651, // Source Platform
            360000086966, // Network Information
            360000086866, // App Version
            22871957, // Legacy Logs
            25176023, // Sub Category
            10901699622036, // Logs
            360000089123 // Device Free Space
        ].sorted())
    }

    func test_ipp_formID_has_correct_value() {
        let dataSource = IPPSupportDataSource(metadataProvider: SupportFormMetadataProvider())
        XCTAssertEqual(dataSource.formID, 360000010286)
    }

    func test_ipp_tags_have_correct_values() {
        // Given
        let dataSource = IPPSupportDataSource(metadataProvider: SupportFormMetadataProvider())
        let tagsSet = Set(dataSource.tags)
        let expectedSet = Set(["iOS", "woocommerce_payments", "woocommerce_mobile_apps", "product_area_apps_in_person_payments"])

        // When & Then
        XCTAssertTrue(expectedSet.isSubset(of: tagsSet))
    }

    func test_ipp_fields_have_correct_ids() {
        let dataSource = IPPSupportDataSource(metadataProvider: SupportFormMetadataProvider())
        let customFieldsKeys = dataSource.customFields.keys.sorted()
        XCTAssertEqual(customFieldsKeys, [
            360008583691, // App Language
            360000103103, // Current Site
            360009311651, // Source Platform
            360000086966, // Network Information
            360000086866, // App Version
            22871957, // Legacy Logs
            25176023, // Sub Category
            10901699622036, // Logs
            360000089123 // Device Free Space
        ].sorted())
    }

    func test_wc_plugins_formID_has_correct_value() {
        let dataSource = WCPluginsSupportDataSource(metadataProvider: SupportFormMetadataProvider())
        XCTAssertEqual(dataSource.formID, 189946)
    }

    func test_wc_plugins_tags_have_correct_values() {
        // Given
        let dataSource = WCPluginsSupportDataSource(metadataProvider: SupportFormMetadataProvider())
        let tagsSet = Set(dataSource.tags)
        let expectedSet = Set(["iOS", "mobile_app_woo_transfer", "woocommerce_core", "support"])

        // When & Then
        XCTAssertTrue(expectedSet.isSubset(of: tagsSet))
    }

    func test_wc_plugins_fields_have_correct_ids() {
        let dataSource = WCPluginsSupportDataSource(metadataProvider: SupportFormMetadataProvider())
        let customFieldsKeys = dataSource.customFields.keys.sorted()
        XCTAssertEqual(customFieldsKeys, [
            360008583691, // App Language
            360000103103, // Current Site
            360009311651, // Source Platform
            360000086966, // Network Information
            360000086866, // App Version
            22871957, // Legacy Logs
            25176003, // Category
            10901699622036, // Logs
            360000089123 // Device Free Space
        ].sorted())
    }

    func test_wcpay_formID_has_correctValue() {
        let dataSource = WCPaySupportDataSource(metadataProvider: SupportFormMetadataProvider())
        XCTAssertEqual(dataSource.formID, 189946)
    }

    func test_wcpay_tags_have_correct_values() {
        let dataSource = WCPaySupportDataSource(metadataProvider: SupportFormMetadataProvider())
        let tagsSet = Set(dataSource.tags)
        let expectedSet = Set(["iOS", "mobile_app_woo_transfer", "woocommerce_payments", "support", "payment", "product_area_woo_payment_gateway"])

        // When & Then
        XCTAssertTrue(expectedSet.isSubset(of: tagsSet))
    }

    func test_wcpay_custom_fields_have_correct_values() {
        let dataSource = WCPaySupportDataSource(metadataProvider: SupportFormMetadataProvider())
        let customFieldsKeys = dataSource.customFields.keys.sorted()
        XCTAssertEqual(customFieldsKeys, [
            360008583691, // App Language
            360000103103, // Current Site
            360009311651, // Source Platform
            360000086966, // Network Information
            360000086866, // App Version
            22871957, // Legacy Logs
            25176003, // Category
            25176023, // Sub Category
            10901699622036, // Logs
            360000089123 // Device Free Space
        ].sorted())
    }

    func test_other_plugins_formID_has_correctValue() {
        let dataSource = OtherPluginsSupportDataSource(metadataProvider: SupportFormMetadataProvider())
        XCTAssertEqual(dataSource.formID, 189946)
    }

    func test_other_plugins_tags_have_correct_values() {
        let dataSource = OtherPluginsSupportDataSource(metadataProvider: SupportFormMetadataProvider())
        let tagsSet = Set(dataSource.tags)
        let expectedSet = Set(["iOS", "product_area_woo_extensions", "mobile_app_woo_transfer", "support", "store"])

        // When & Then
        XCTAssertTrue(expectedSet.isSubset(of: tagsSet))
    }

    func test_other_plugins_custom_fields_have_correct_values() {
        let dataSource = OtherPluginsSupportDataSource(metadataProvider: SupportFormMetadataProvider())
        let customFieldsKeys = dataSource.customFields.keys.sorted()
        XCTAssertEqual(customFieldsKeys, [
            360008583691, // App Language
            360000103103, // Current Site
            360009311651, // Source Platform
            360000086966, // Network Information
            360000086866, // App Version
            22871957, // Legacy Logs
            25176003, // Category
            25176023, // Sub Category
            10901699622036, // Logs
            360000089123 // Device Free Space
        ].sorted())
    }
}
