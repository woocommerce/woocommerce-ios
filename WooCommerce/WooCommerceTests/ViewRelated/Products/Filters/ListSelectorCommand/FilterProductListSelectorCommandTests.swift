import XCTest
@testable import WooCommerce
@testable import Yosemite

final class FilterProductListSelectorCommandTests: XCTestCase {
    func testSelectedIsAlwaysNilAfterSelections() {
        let filters = FilterProductListCommand.Filters(stockStatus: .inStock, productStatus: nil, productType: nil)
        let command = FilterProductListSelectorCommand(filters: filters, onFilterSelected: { _, _  in })
        let viewController = ListSelectorViewController(command: command, onDismiss: { _ in })
        XCTAssertNil(command.selected)

        command.handleSelectedChange(selected: .productType, viewController: viewController)
        XCTAssertNil(command.selected)

        command.handleSelectedChange(selected: .productStatus, viewController: viewController)
        XCTAssertNil(command.selected)

        command.handleSelectedChange(selected: .stockStatus, viewController: viewController)
        XCTAssertNil(command.selected)
    }

    func testCellConfigurationForOptionalFilterValues() {
        let filters = FilterProductListCommand.Filters(stockStatus: .inStock, productStatus: nil, productType: .affiliate)
        let command = FilterProductListSelectorCommand(filters: filters, onFilterSelected: { _, _  in })
        let nib = Bundle.main.loadNibNamed(SettingTitleAndValueTableViewCell.classNameWithoutNamespaces, owner: self, options: nil)
        guard let cell = nib?.first as? SettingTitleAndValueTableViewCell else {
            XCTFail()
            return
        }

        command.configureCell(cell: cell, model: .stockStatus)
        XCTAssertEqual(cell.valueLabel.text, ProductStockStatus.inStock.description)

        command.configureCell(cell: cell, model: .productStatus)
        XCTAssertEqual(cell.valueLabel.text, NSLocalizedString("Any", comment: "Title when there is no filter set."))

        command.configureCell(cell: cell, model: .productType)
        XCTAssertEqual(cell.valueLabel.text, ProductType.affiliate.description)
    }

    // MARK: - Navigation bar title

    func testNavigationBarTitleWithoutActiveFilters() {
        let filters = FilterProductListCommand.Filters(stockStatus: nil, productStatus: nil, productType: nil)
        let command = FilterProductListSelectorCommand(filters: filters, onFilterSelected: { _, _  in })

        let expectedTitle = NSLocalizedString("Filters", comment: "Navigation bar title format for filtering a list of products without filters applied.")
        XCTAssertEqual(command.navigationBarTitle, expectedTitle)
    }

    func testNavigationBarTitleWithTwoActiveFilters() {
        let filters = FilterProductListCommand.Filters(stockStatus: .inStock, productStatus: nil, productType: .affiliate)
        let command = FilterProductListSelectorCommand(filters: filters, onFilterSelected: { _, _  in })

        let format = NSLocalizedString("Filters (%ld)", comment: "Navigation bar title format for filtering a list of products with filters applied.")
        let expectedTitle = String.localizedStringWithFormat(format, 2)
        XCTAssertEqual(command.navigationBarTitle, expectedTitle)
    }
}
