import Foundation
import Yosemite

/// Command to populate the attribute option selector for variable product
///
final class AttributeOptionListSelectorCommand: ListSelectorCommand {

    enum Row: Equatable {
        case anyOption(String)
        case option(String)
    }

    typealias Model = Row
    typealias Cell = BasicTableViewCell

    let navigationBarTitle: String?

    private(set) var selected: Row?

    let data: [Row]

    init(attribute: ProductAttribute, selectedOption: ProductVariationAttribute?) {
        self.navigationBarTitle = attribute.name
        self.data = [Row.anyOption(attribute.name)] + attribute.options.map { Row.option($0) }

        if let selectedOption = selectedOption {
            self.selected = .option(selectedOption.option)
        } else {
            self.selected = .anyOption(attribute.name)
        }
    }

    func configureCell(cell: BasicTableViewCell, model: Row) {
        switch model {
        case .anyOption(let attributeName):
            cell.textLabel?.text = String.localizedStringWithFormat(Localization.anyOption, attributeName)
        case .option(let optionName):
            cell.textLabel?.text = optionName
        }
        cell.textLabel?.numberOfLines = 0
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
            "Any %1$@",
            comment: "Product variation attribute description where the attribute is set to any value.")
    }
}
