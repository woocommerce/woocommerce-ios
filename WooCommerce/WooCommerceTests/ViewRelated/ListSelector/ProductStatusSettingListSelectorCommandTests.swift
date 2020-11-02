import XCTest

@testable import WooCommerce
@testable import Yosemite

final class ProductStatusSettingListSelectorCommandTests: XCTestCase {

    func test_selected_setting() {
        let expectedSetting = ProductStatus.publish
        let product = MockProduct().product(status: expectedSetting)
        let command = ProductStatusSettingListSelectorCommand(selected: product.productStatus)
        let viewController = ListSelectorViewController(command: command, onDismiss: { _ in })
        XCTAssertEqual(command.selected, expectedSetting)

        let newSetting = ProductStatus.pending
        command.handleSelectedChange(selected: newSetting, viewController: viewController)
        XCTAssertEqual(command.selected, newSetting)
    }

    func test_setting_list_data() {
        let command = ProductStatusSettingListSelectorCommand(selected: nil)
        XCTAssertEqual(command.data.count, 3)
    }

    func test_cell_configuration() {
        let product = MockProduct().product()
        let command = ProductStatusSettingListSelectorCommand(selected: product.productStatus)
        let nib = Bundle.main.loadNibNamed(BasicTableViewCell.classNameWithoutNamespaces, owner: self, options: nil)
        guard let cell = nib?.first as? BasicTableViewCell else {
            XCTFail()
            return
        }

        command.configureCell(cell: cell, model: product.productStatus)

        XCTAssertEqual(cell.textLabel?.text, product.productStatus.description)
    }

}
