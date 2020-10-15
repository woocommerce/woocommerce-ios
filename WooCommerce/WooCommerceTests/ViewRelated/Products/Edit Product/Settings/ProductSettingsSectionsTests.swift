import XCTest
@testable import WooCommerce
import Yosemite

/// Test cases for `ProductSettingsSections`.
///
final class ProductSettingsSectionsTests: XCTestCase {

    func testGivenANonSimpleProductThenItDoesNotShowTheVirtualProductOption() {
        // Given
        let settings = ProductSettings(status: .draft,
                                       featured: false,
                                       password: nil,
                                       catalogVisibility: .catalog,
                                       virtual: false,
                                       reviewsAllowed: false,
                                       slug: "",
                                       purchaseNote: nil,
                                       menuOrder: 0)
        let productType = ProductType.grouped

        // When
        let section = ProductSettingsSections.PublishSettings(settings, productType: productType)

        // Then
        XCTAssertNil(section.rows.first(where: {
            $0 is ProductSettingsRows.VirtualProduct
        }))
    }

    func testGivenASimpleProductThenItShowsTheVirtualProductOption() {
        // Given
        let settings = ProductSettings(status: .draft,
                                       featured: false,
                                       password: nil,
                                       catalogVisibility: .catalog,
                                       virtual: false,
                                       reviewsAllowed: false,
                                       slug: "",
                                       purchaseNote: nil,
                                       menuOrder: 0)
        let productType = ProductType.simple

        // When
        let section = ProductSettingsSections.PublishSettings(settings, productType: productType)

        // Then
        XCTAssertNotNil(section.rows.first(where: {
            $0 is ProductSettingsRows.VirtualProduct
        }))
    }
}
