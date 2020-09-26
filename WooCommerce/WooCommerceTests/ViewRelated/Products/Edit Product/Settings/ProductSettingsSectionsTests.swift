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
                                       menuOrder: 0,
                                       downloadable: false)
        let productType = ProductType.grouped

        // When
        let section = ProductSettingsSections.PublishSettings(settings, productType: productType, isEditProductsRelease3Enabled: true, isEditProductsRelease5Enabled: false)

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
                                       menuOrder: 0,
                                       downloadable: false)
        let productType = ProductType.simple

        // When
        let section = ProductSettingsSections.PublishSettings(settings, productType: productType, isEditProductsRelease3Enabled: true, isEditProductsRelease5Enabled: false)

        // Then
        XCTAssertNotNil(section.rows.first(where: {
            $0 is ProductSettingsRows.VirtualProduct
        }))
    }

    func test_given_a_non_simple_product_then_it_does_not_show_the_downloadable_product_option() {
        // Given
        let settings = ProductSettings(status: .draft,
                                       featured: false,
                                       password: nil,
                                       catalogVisibility: .catalog,
                                       virtual: false,
                                       reviewsAllowed: false,
                                       slug: "",
                                       purchaseNote: nil,
                                       menuOrder: 0,
                                       downloadable: false)
        let productType = ProductType.grouped

        // When
        let section = ProductSettingsSections.PublishSettings(settings, productType: productType, isEditProductsRelease3Enabled: true, isEditProductsRelease5Enabled: true)

        // Then
        XCTAssertNil(section.rows.first(where: {
            $0 is ProductSettingsRows.DownloadableProduct
        }))
    }

    func test_given_a_simple_product_then_it_shows_the_downloadable_product_option() {
        // Given
        let settings = ProductSettings(status: .draft,
                                       featured: false,
                                       password: nil,
                                       catalogVisibility: .catalog,
                                       virtual: false,
                                       reviewsAllowed: false,
                                       slug: "",
                                       purchaseNote: nil,
                                       menuOrder: 0,
                                       downloadable: false)
        let productType = ProductType.simple

        // When
        let section = ProductSettingsSections.PublishSettings(settings, productType: productType, isEditProductsRelease3Enabled: true, isEditProductsRelease5Enabled: true)

        // Then
        XCTAssertNotNil(section.rows.first(where: {
            $0 is ProductSettingsRows.DownloadableProduct
        }))
    }
}
