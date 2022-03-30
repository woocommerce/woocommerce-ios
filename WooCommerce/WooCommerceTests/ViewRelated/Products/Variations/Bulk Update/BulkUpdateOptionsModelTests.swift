import XCTest
import Yosemite
import Combine
@testable import Storage

@testable import WooCommerce

/// Tests for `BulkUpdateFormModel`.
///
final class BulkUpdateOptionsModelTests: XCTestCase {

    func test_regular_price_bulk_value_when_empty_array_of_product_variations() {
        // Given
        let formModel = BulkUpdateOptionsModel(productVariations: [])

        // When
        let regularPrice = formModel.bulkValueOf(\.regularPrice)

        // Then
        XCTAssertEqual(regularPrice, .none)
    }

    func test_regular_price_bulk_value_when_product_variations_have_no_price() {
        // Given
        let variations = [MockProductVariation().productVariation(),
                          MockProductVariation().productVariation()]

        let formModel = BulkUpdateOptionsModel(productVariations: variations)

        // When
        let regularPrice = formModel.bulkValueOf(\.regularPrice)

        // Then
        XCTAssertEqual(regularPrice, .none)
    }

    func test_regular_price_bulk_value_when_product_variations_have_same_prices() {
        // Given
        let variations = [MockProductVariation().productVariation().copy(regularPrice: "1"),
                          MockProductVariation().productVariation().copy(regularPrice: "1")]

        let formModel = BulkUpdateOptionsModel(productVariations: variations)

        // When
        let regularPrice = formModel.bulkValueOf(\.regularPrice)

        // Then
        XCTAssertEqual(regularPrice, .value("1"))
    }

    func test_regular_price_bulk_value_when_product_variations_have_different_prices() {
        // Given
        let variations = [MockProductVariation().productVariation().copy(regularPrice: "1"),
                          MockProductVariation().productVariation().copy(regularPrice: "2")]

        let formModel = BulkUpdateOptionsModel(productVariations: variations)

        // When
        let regularPrice = formModel.bulkValueOf(\.regularPrice)

        // Then
        XCTAssertEqual(regularPrice, .mixed)
    }
}
