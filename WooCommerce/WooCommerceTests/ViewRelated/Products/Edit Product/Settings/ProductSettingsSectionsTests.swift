import XCTest
@testable import WooCommerce
import Yosemite

/// Test cases for `ProductSettingsSections`.
///
final class ProductSettingsSectionsTests: XCTestCase {

    func test_given_a_non_simple_product_then_it_does_not_show_the_virtual_product_option() {
        // Given
        let settings = ProductSettings(productType: .grouped,
                                       status: .draft,
                                       featured: false,
                                       password: nil,
                                       catalogVisibility: .catalog,
                                       virtual: false,
                                       reviewsAllowed: false,
                                       slug: "",
                                       purchaseNote: nil,
                                       menuOrder: 0,
                                       downloadable: false)

        // When
        let section = ProductSettingsSections.PublishSettings(settings)

        // Then
        XCTAssertNil(section.rows.first(where: {
            $0 is ProductSettingsRows.VirtualProduct
        }))
    }

    func test_given_a_simple_product_then_it_shows_the_virtual_product_option() {
        // Given
        let settings = ProductSettings(productType: .simple,
                                       status: .draft,
                                       featured: false,
                                       password: nil,
                                       catalogVisibility: .catalog,
                                       virtual: false,
                                       reviewsAllowed: false,
                                       slug: "",
                                       purchaseNote: nil,
                                       menuOrder: 0,
                                       downloadable: false)

        // When
        let section = ProductSettingsSections.PublishSettings(settings)

        // Then
        XCTAssertNotNil(section.rows.first(where: {
            $0 is ProductSettingsRows.VirtualProduct
        }))
    }

    func test_given_a_non_simple_product_then_it_does_not_show_the_downloadable_product_option() {
         // Given
         let settings = ProductSettings(productType: .grouped,
                                        status: .draft,
                                        featured: false,
                                        password: nil,
                                        catalogVisibility: .catalog,
                                        virtual: false,
                                        reviewsAllowed: false,
                                        slug: "",
                                        purchaseNote: nil,
                                        menuOrder: 0,
                                        downloadable: false)

          // When
        let section = ProductSettingsSections.PublishSettings(settings)

          // Then
         XCTAssertNil(section.rows.first(where: {
             $0 is ProductSettingsRows.DownloadableProduct
         }))
     }

      func test_given_a_simple_product_then_it_shows_the_downloadable_product_option() {
         // Given
         let settings = ProductSettings(productType: .simple,
                                        status: .draft,
                                        featured: false,
                                        password: nil,
                                        catalogVisibility: .catalog,
                                        virtual: false,
                                        reviewsAllowed: false,
                                        slug: "",
                                        purchaseNote: nil,
                                        menuOrder: 0,
                                        downloadable: false)

          // When
          let section = ProductSettingsSections.PublishSettings(settings)

          // Then
         XCTAssertNotNil(section.rows.first(where: {
             $0 is ProductSettingsRows.DownloadableProduct
         }))
     }
}
