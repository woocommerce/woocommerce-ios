import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductPriceSettingsViewModel_ProductVariationTests: XCTestCase {
    // MARK: - Sections (where logic changes between `Product` and `ProductVariation`

    private typealias Section = ProductPriceSettingsViewModel.Section

    func testInitialSectionsWithoutSaleDates() {
        // Arrange
        let saleStartDate: Date? = nil
        let saleEndDate: Date? = nil
        let productVariation = MockProductVariation().productVariation().copy(dateOnSaleStart: saleStartDate, dateOnSaleEnd: saleEndDate)
        let model = EditableProductVariationModel(productVariation: productVariation)
        let viewModel = ProductPriceSettingsViewModel(product: model)

        // Act
        let sections = viewModel.sections

        // Assert
        let initialSections: [Section] = [
            Section(title: ProductPriceSettingsViewModel.Strings.priceSectionTitle, rows: [.price, .salePrice]),
            Section(title: nil, rows: [.scheduleSale]),
        ]
        XCTAssertEqual(sections, initialSections)
    }

    func testTappingScheduleSaleToRowTogglesPickerRowInSalesSection() {
        // Arrange
        let saleStartDate: Date? = nil
        let saleEndDate = Date()
        let productVariation = MockProductVariation().productVariation().copy(dateOnSaleStart: saleStartDate, dateOnSaleEnd: saleEndDate)
        let model = EditableProductVariationModel(productVariation: productVariation)
        let viewModel = ProductPriceSettingsViewModel(product: model)
        let initialSections: [Section] = [
            Section(title: ProductPriceSettingsViewModel.Strings.priceSectionTitle, rows: [.price, .salePrice]),
            Section(title: nil, rows: [.scheduleSale, .scheduleSaleFrom, .scheduleSaleTo, .removeSaleTo]),
        ]
        XCTAssertEqual(viewModel.sections, initialSections)

        // Act
        viewModel.didTapScheduleSaleToRow()
        let sectionsAfterTheFirstTap = viewModel.sections
        viewModel.didTapScheduleSaleToRow()
        let sectionsAfterTheSecondTap = viewModel.sections

        // Assert
        XCTAssertEqual(sectionsAfterTheFirstTap, [
            Section(title: ProductPriceSettingsViewModel.Strings.priceSectionTitle, rows: [.price, .salePrice]),
            Section(title: nil, rows: [.scheduleSale, .scheduleSaleFrom, .scheduleSaleTo, .datePickerSaleTo, .removeSaleTo]),
        ])
        XCTAssertEqual(sectionsAfterTheSecondTap, initialSections)
    }

    func testRemovingSaleEndDateDeletesRemoveSaleToRow() {
        // Arrange
        let saleStartDate: Date? = nil
        let saleEndDate = Date()
        let productVariation = MockProductVariation().productVariation().copy(dateOnSaleStart: saleStartDate, dateOnSaleEnd: saleEndDate)
        let model = EditableProductVariationModel(productVariation: productVariation)
        let viewModel = ProductPriceSettingsViewModel(product: model)
        let initialSections: [Section] = [
            Section(title: ProductPriceSettingsViewModel.Strings.priceSectionTitle, rows: [.price, .salePrice]),
            Section(title: nil, rows: [.scheduleSale, .scheduleSaleFrom, .scheduleSaleTo, .removeSaleTo]),
        ]
        XCTAssertEqual(viewModel.sections, initialSections)

        // Act
        viewModel.handleSaleEndDateChange(nil)

        // Assert
        XCTAssertEqual(viewModel.sections, [
            Section(title: ProductPriceSettingsViewModel.Strings.priceSectionTitle, rows: [.price, .salePrice]),
            Section(title: nil, rows: [.scheduleSale, .scheduleSaleFrom, .scheduleSaleTo]),
        ])
    }
}
