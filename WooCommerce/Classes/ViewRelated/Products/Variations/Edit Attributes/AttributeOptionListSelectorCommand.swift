import Foundation
import Yosemite

/// Command to populate the attribute option selector for variable product
///
final class AttributeOptionListSelectorCommand: ListSelectorCommand {

    enum Row: Equatable {
        case anyOption
        case option(String)
    }

    typealias Model = Row
    typealias Cell = BasicTableViewCell

    let navigationBarTitle: String?

    private(set) var selected: Row?

    let data: [Row]

    init(attribute: ProductAttribute, selectedOption: ProductVariationAttribute?) {
        self.navigationBarTitle = attribute.name
        self.data = [Row.anyOption] + attribute.options.map { Row.option($0) }

        if let selectedOption = selectedOption {
            self.selected = .option(selectedOption.option)
        } else {
            self.selected = .anyOption
        }
    }

    func configureCell(cell: BasicTableViewCell, model: Row) {
        switch model {
        case .anyOption:
            cell.textLabel?.text = Localization.anyOption
        case .option(let optionName):
            cell.textLabel?.text = optionName
        }
    }

    func handleSelectedChange(selected: Row, viewController: ViewController) {
        self.selected = selected
    }

    func isSelected(model: Row) -> Bool {
        return model == selected
    }
}

private extension AttributeOptionListSelectorCommand {
    enum Localization {
        static let anyOption = NSLocalizedString(
            "Any Attribute",
            comment: "Product variation attribute description where the attribute is set to any value.")
    }
}
