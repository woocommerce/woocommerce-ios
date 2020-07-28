import XCTest
@testable import WooCommerce
import Yosemite

/// Test cases for `ProductSettingsRows`.
///
final class ProductSettingsRowsTests: XCTestCase {

    var originalSettings: ProductSettings?

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
                                       menuOrder: 0)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testVirtualProductRowChangedWhenUpdated() throws {
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

    func testReviewsAllowedRowChangedWhenUpdated() throws {
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
}
