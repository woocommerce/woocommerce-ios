import Foundation
import Yosemite

final class AttributeOptionPickerViewModel {

    typealias Row = AttributeOptionPickerViewController.Row

    private let attribute: ProductAttribute
    private let originalOption: String?
    private var selectedOption: String?

    init(attribute: ProductAttribute, selectedOption: ProductVariationAttribute?) {
        self.attribute = attribute
        self.originalOption = selectedOption?.option
        self.selectedOption = selectedOption?.option
    }

    // MARK: DataSource

    var attributeName: String {
        attribute.name
    }

    var isChanged: Bool {
        originalOption != selectedOption
    }

    lazy var allRows: [Row] = {
        [Row.anyAttribute] + attribute.options.map { Row.option($0) }
    }()

    var selectedRow: Row {
        if let selectedOption = selectedOption {
            return .option(selectedOption)
        } else {
            return .anyAttribute
        }
    }

    var resultAttribute: ProductVariationAttribute? {
        if let selectedOption = selectedOption {
            return ProductVariationAttribute(id: attribute.attributeID, name: attribute.name, option: selectedOption)
        } else {
            return nil
        }
    }

    // MARK: Delegate

    func selectRow(at indexPath: IndexPath) {
        guard let row = allRows[safe: indexPath.row] else {
            return
        }

        switch row {
        case .anyAttribute:
            selectedOption = nil
        case .option(let optionName):
            selectedOption = optionName
        }
    }
}
