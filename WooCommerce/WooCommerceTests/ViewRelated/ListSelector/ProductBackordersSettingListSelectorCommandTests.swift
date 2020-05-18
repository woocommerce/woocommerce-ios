import XCTest

@testable import WooCommerce
@testable import Yosemite

final class ProductBackordersSettingListSelectorCommandTests: XCTestCase {

    func testSelectedSetting() {
        let expectedSetting = ProductBackordersSetting.notAllowed
        let product = MockProduct().product(backordersSetting: expectedSetting)
        let command = ProductBackordersSettingListSelectorCommand(selected: product.backordersSetting)
        let viewController = ListSelectorViewController(command: command, onDismiss: { _ in })
        XCTAssertEqual(command.selected, expectedSetting)

        let newSetting = ProductBackordersSetting.allowedAndNotifyCustomer
        command.handleSelectedChange(selected: newSetting, viewController: viewController)
        XCTAssertEqual(command.selected, newSetting)
    }

    func testSettingListData() {
        let command = ProductBackordersSettingListSelectorCommand(selected: nil)
        XCTAssertEqual(command.data.count, 3)
    }

    func testCellConfiguration() {
        let product = MockProduct().product()
        let command = ProductBackordersSettingListSelectorCommand(selected: product.backordersSetting)
        let nib = Bundle.main.loadNibNamed(BasicTableViewCell.classNameWithoutNamespaces, owner: self, options: nil)
        guard let cell = nib?.first as? BasicTableViewCell else {
            XCTFail()
            return
        }

        command.configureCell(cell: cell, model: product.backordersSetting)

        XCTAssertEqual(cell.textLabel?.text, product.backordersSetting.description)
    }

}
