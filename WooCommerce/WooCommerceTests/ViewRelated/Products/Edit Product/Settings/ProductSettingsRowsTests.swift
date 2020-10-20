import XCTest
@testable import WooCommerce
import Yosemite

/// Test cases for `ProductSettingsRows`.
///
final class ProductSettingsRowsTests: XCTestCase {

    private var originalSettings: ProductSettings?

    override func setUp() {
        super.setUp()

        // Given
        originalSettings = ProductSettings(status: .draft,
                                       featured: false,
                                       password: nil,
                                       catalogVisibility: .catalog,
                                       virtual: false,
                                       reviewsAllowed: false,
                                       slug: "",
                                       purchaseNote: nil,
                                       menuOrder: 0,
                                       downloadable: false)
    }

    override func tearDown() {
        super.tearDown()
    }

    func test_virtual_product_row_changed_when_updated() throws {
        let settings = try XCTUnwrap(originalSettings)

        // Given
        let virtualProduct = ProductSettingsRows.VirtualProduct(settings)

        let cell = SwitchTableViewCell()
        virtualProduct.configure(cell: cell)

        // When
        cell.onChange?(true)

        // Then
        XCTAssertEqual(settings.virtual, true)
    }

    func test_reviewsAllowed_row_changed_when_updated() throws {
        let settings = try XCTUnwrap(originalSettings)

        // Given
        let reviewsAllowed = ProductSettingsRows.ReviewsAllowed(settings)

        let cell = SwitchTableViewCell()
        reviewsAllowed.configure(cell: cell)

        // When
        cell.onChange?(true)

        // Then
        XCTAssertEqual(settings.reviewsAllowed, true)
    }

    func test_downloadable_product_row_changed_when_updated() throws {
         let settings = try XCTUnwrap(originalSettings)

          // Given
         let downloadableProduct = ProductSettingsRows.DownloadableProduct(settings)

          let cell = SwitchTableViewCell()
         downloadableProduct.configure(cell: cell)

          // When
         cell.onChange?(true)

          // Then
         XCTAssertEqual(settings.downloadable, true)
     }
}
