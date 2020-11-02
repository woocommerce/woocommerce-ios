import XCTest

@testable import WooCommerce
@testable import Yosemite

final class ProductTaxStatusListSelectorCommandTests: XCTestCase {

    func test_selected_taxStatus() {

        let taxStatus = ProductTaxStatus.taxable
        let command = ProductTaxStatusListSelectorCommand(selected: taxStatus)
        let viewController = ListSelectorViewController(command: command, onDismiss: { _ in })
        XCTAssertEqual(command.selected, taxStatus)

        let newTaxStatus = ProductTaxStatus.shipping
        command.handleSelectedChange(selected: newTaxStatus, viewController: viewController)
        XCTAssertEqual(command.selected, newTaxStatus)

        // Select the same data twice should not clear the selected data.
        command.handleSelectedChange(selected: newTaxStatus, viewController: viewController)
        XCTAssertNotNil(command.selected)
    }

    func test_cell_configuration() {
        let taxStatus = ProductTaxStatus.taxable
        let command = ProductTaxStatusListSelectorCommand(selected: taxStatus)
        let nib = Bundle.main.loadNibNamed(BasicTableViewCell.classNameWithoutNamespaces, owner: self, options: nil)
        guard let cell = nib?.first as? BasicTableViewCell else {
            XCTFail()
            return
        }

        command.configureCell(cell: cell, model: taxStatus)

        XCTAssertEqual(cell.textLabel?.text, taxStatus.description)
    }

}
