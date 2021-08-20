import XCTest
import TestKit

@testable import WooCommerce
@testable import Yosemite

class ProductAddOnViewModelTests: XCTestCase {

    /// Fixed currency formatter for tests
    ///
    private let currencyFormatter = CurrencyFormatter(currencySettings: .init(currencyCode: .USD,
                                                                              currencyPosition: .left,
                                                                              thousandSeparator: ",",
                                                                              decimalSeparator: ".",
                                                                              numberOfDecimals: 2))

    func test_view_model_shows_description_when_price_is_not_empty() {
        // Given
        let viewModel = ProductAddOnViewModel(name: "", description: "", price: "$20.99", options: [])

        // Then & When
        XCTAssertTrue(viewModel.showDescription)
        XCTAssertTrue(viewModel.showPrice)
    }

    func test_view_model_hides_description_and_price_when_empty() {
        // Given
        let viewModel = ProductAddOnViewModel(name: "", description: "", price: "", options: [
            .init(name: "", price: "", offSetDivider: false)
        ])

        // Then & When
        XCTAssertFalse(viewModel.showDescription)
        XCTAssertFalse(viewModel.showPrice)
        XCTAssertFalse(viewModel.options[0].showPrice)
    }

    func test_view_model_shows_description_and_price_when_not_empty() {
        // Given
        let viewModel = ProductAddOnViewModel(name: "", description: "Description", price: "$20.99", options: [
            .init(name: "", price: "$20.99", offSetDivider: false)
        ])

        // Then & When
        XCTAssertTrue(viewModel.showDescription)
        XCTAssertTrue(viewModel.showPrice)
        XCTAssertTrue(viewModel.options[0].showPrice)
    }

    func test_bottom_divider_is_visible_when_no_options() {
        // Given
        let viewModel = ProductAddOnViewModel(name: "Name", description: "Description", price: "$20.99", options: [])

        // Then & When
        XCTAssertTrue(viewModel.showBottomDivider)
    }

    func test_fields_are_properly_populated_from_entity() {
        // Given
        let productAddOn = Yosemite.ProductAddOn.fake().copy(name: "Name", description: "Description", price: "20.0", options: [
            ProductAddOnOption.fake().copy(label: "Option 1", price: "11.0"),
            ProductAddOnOption.fake().copy(label: "Option 2", price: "9.0"),
        ])

        // When
        let viewModel = ProductAddOnViewModel(addOn: productAddOn, currencyFormatter: currencyFormatter)

        // Then
        let expected = ProductAddOnViewModel(name: "Name", description: "Description", price: "$20.00", options: [
            .init(name: "Option 1", price: "$11.00", offSetDivider: true),
            .init(name: "Option 2", price: "$9.00", offSetDivider: false),
        ])
        assertEqual(viewModel, expected)
    }

    func test_empty_options_are_excluded() {
        // Given
        let productAddOn = Yosemite.ProductAddOn.fake().copy(name: "Name", description: "Description", price: "20.0", options: [
            ProductAddOnOption.fake().copy(label: "", price: ""),
            ProductAddOnOption.fake().copy(label: "Option 1", price: "11.0"),
        ])

        // When
        let viewModel = ProductAddOnViewModel(addOn: productAddOn, currencyFormatter: currencyFormatter)

        // Then
        let expected = ProductAddOnViewModel(name: "Name", description: "Description", price: "$20.00", options: [
            .init(name: "Option 1", price: "$11.00", offSetDivider: false),
        ])
        assertEqual(viewModel, expected)
    }

    func test_percentage_options_are_properly_formatted_from_entity() {
        // Given
        let productAddOn = Yosemite.ProductAddOn.fake().copy(name: "Name", description: "Description", price: "20.0", options: [
            ProductAddOnOption.fake().copy(label: "Option 1", price: "9", priceType: .percentageBased),
            ProductAddOnOption.fake().copy(label: "Option 2", price: "5.3", priceType: .percentageBased),
        ])

        // When
        let viewModel = ProductAddOnViewModel(addOn: productAddOn, currencyFormatter: currencyFormatter)

        // Then
        let expected = ProductAddOnViewModel(name: "Name", description: "Description", price: "$20.00", options: [
            .init(name: "Option 1", price: "9%", offSetDivider: true),
            .init(name: "Option 2", price: "5.3%", offSetDivider: false),
        ])
        assertEqual(viewModel, expected)
    }
}
