import XCTest
@testable import WooCommerce

final class SupportDataSourcesTests: XCTestCase {

    func test_general_formID_has_correct_value() {
        let dataSource = GeneralSupportDataSource()
        XCTAssertEqual(dataSource.formID, 360000010286)
    }

    func test_general_tags_have_correct_values() {
        // Given
        let dataSource = GeneralSupportDataSource()
        let tagsSet = Set(dataSource.tags)
        let expectedSet = Set(["iOS", "woo-mobile-sdk", "jetpack"])

        // When & Then
        XCTAssertTrue(expectedSet.isSubset(of: tagsSet))
    }

    func test_general_custom_fields_have_correct_ids() {
        let dataSource = GeneralSupportDataSource()
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

    func test_wcpay_formID_has_correctValue() {
        let dataSource = WCPaySupportDataSource()
        XCTAssertEqual(dataSource.formID, 189946)
    }

    func test_wcpay_tags_have_correct_values() {
        let dataSource = WCPaySupportDataSource()
        let tagsSet = Set(dataSource.tags)
        let expectedSet = Set(["iOS", "woo-mobile-sdk", "woocommerce_payments", "support", "payment", "product_area_woo_payment_gateway"])

        // When & Then
        XCTAssertTrue(expectedSet.isSubset(of: tagsSet))
    }

    func test_wcpay_custom_fields_have_correct_values() {
        let dataSource = WCPaySupportDataSource()
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
