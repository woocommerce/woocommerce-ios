import XCTest
@testable import WooCommerce
@testable import Yosemite

/// Tests for `ProductPriceSettingsValidator`
///
final class ProductPriceSettingsValidatorTests: XCTestCase {

    private var productValidator: ProductPriceSettingsValidator!

    override func setUp() {
        super.setUp()
        productValidator = ProductPriceSettingsValidator(currencySettings: CurrencySettings())
    }

    override func tearDown() {
        productValidator = nil
        super.tearDown()
    }

    func test_validation_with_sale_date_range_with_nil_regular_price() {
        // Given
        let dateOnSaleStart = date(from: "2019-09-02T21:30:00")
        let dateOnSaleEnd = date(from: "2019-09-27T21:30:00")
        let regularPrice: String? = nil
        let salePrice = "10.0"

        // When
        let error = productValidator.validate(regularPrice: regularPrice, salePrice: salePrice, dateOnSaleStart: dateOnSaleStart, dateOnSaleEnd: dateOnSaleEnd)

        // Then
        XCTAssertEqual(error, .salePriceWithoutRegularPrice)
    }

    func test_validation_with_sale_date_range_with_nil_sale_price() {
        // Given
        let dateOnSaleStart = date(from: "2019-09-02T21:30:00")
        let dateOnSaleEnd = date(from: "2019-09-27T21:30:00")
        let regularPrice = "10.0"
        let salePrice: String? = nil

        // When
        let error = productValidator.validate(regularPrice: regularPrice, salePrice: salePrice, dateOnSaleStart: dateOnSaleStart, dateOnSaleEnd: dateOnSaleEnd)

        // Then
        XCTAssertEqual(error, .newSaleWithEmptySalePrice)
    }

    func test_validation_with_sale_date_range_with_nil_sale_and_regular_price() {
        // Given
        let dateOnSaleStart = date(from: "2019-09-02T21:30:00")
        let dateOnSaleEnd = date(from: "2019-09-27T21:30:00")
        let regularPrice: String? = nil
        let salePrice: String? = nil

        // When
        let error = productValidator.validate(regularPrice: regularPrice, salePrice: salePrice, dateOnSaleStart: dateOnSaleStart, dateOnSaleEnd: dateOnSaleEnd)

        // Then
        XCTAssertEqual(error, .newSaleWithEmptySalePrice)
    }

    func test_validation_with_sale_date_range_and_sale_price_higher_than_regular_price() {
        // Given
        let dateOnSaleStart = date(from: "2019-09-02T21:30:00")
        let dateOnSaleEnd = date(from: "2019-09-27T21:30:00")
        let regularPrice = "10.0"
        let salePrice = "20.0"

        // When
        let error = productValidator.validate(regularPrice: regularPrice, salePrice: salePrice, dateOnSaleStart: dateOnSaleStart, dateOnSaleEnd: dateOnSaleEnd)

        // Then
        XCTAssertEqual(error, .salePriceHigherThanRegularPrice)
    }

    func test_validation_without_sale_date_range_with_nil_regular_price() {
        // Given
        let dateOnSaleStart: Date? = nil
        let dateOnSaleEnd: Date? = nil
        let regularPrice: String? = nil
        let salePrice = "10.0"

        // When
        let error = productValidator.validate(regularPrice: regularPrice, salePrice: salePrice, dateOnSaleStart: dateOnSaleStart, dateOnSaleEnd: dateOnSaleEnd)

        // Then
        XCTAssertEqual(error, .salePriceWithoutRegularPrice)
    }

    func test_validation_without_sale_date_range_with_nil_sale_price() {
        // Given
        let dateOnSaleStart: Date? = nil
        let dateOnSaleEnd: Date? = nil
        let regularPrice: String? = nil
        let salePrice = "10.0"
        // When
        let error = productValidator.validate(regularPrice: regularPrice, salePrice: salePrice, dateOnSaleStart: dateOnSaleStart, dateOnSaleEnd: dateOnSaleEnd)

        // Then
        XCTAssertEqual(error, .salePriceWithoutRegularPrice)
    }

    func test_validation_without_sale_date_range_with_nil_sale_and_regular_price() {
        // Given
        let dateOnSaleStart: Date? = nil
        let dateOnSaleEnd: Date? = nil
        let regularPrice: String? = nil
        let salePrice: String? = nil

        // When
        let error = productValidator.validate(regularPrice: regularPrice, salePrice: salePrice, dateOnSaleStart: dateOnSaleStart, dateOnSaleEnd: dateOnSaleEnd)

        // Then
        XCTAssertNil(error)
    }

    func test_validation_with_sale_date_range_and_regular_price_higher_than_sale_price() {
        // Given
        let dateOnSaleStart = date(from: "2019-09-02T21:30:00")
        let dateOnSaleEnd = date(from: "2019-09-27T21:30:00")
        let regularPrice = "20.0"
        let salePrice = "10.0"

        // When
        let error = productValidator.validate(regularPrice: regularPrice, salePrice: salePrice, dateOnSaleStart: dateOnSaleStart, dateOnSaleEnd: dateOnSaleEnd)

        // Then
        XCTAssertNil(error)
    }

    func test_price_decimal_value() {
        // Given
        let price = "42.0"

        // When
        let priceDecimal = productValidator.getDecimalPrice(price)

        // Then
        XCTAssertEqual(priceDecimal, 42.0)
    }
}

private extension ProductPriceSettingsValidatorTests {

    func date(from dateString: String) -> Date? {
        DateFormatter.Defaults.dateTimeFormatter.date(from: dateString)
    }
}
