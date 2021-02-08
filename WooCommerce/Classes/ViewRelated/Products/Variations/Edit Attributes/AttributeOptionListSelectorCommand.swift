import Foundation
import Yosemite

/// Command to populate the shipping label paper size list selector
///
final class AttributeOptionListSelectorCommand: ListSelectorCommand {

    enum Row: Equatable {
        case anyAttribute
        case option(String)
    }

    typealias Model = Row
    typealias Cell = BasicTableViewCell

    let navigationBarTitle: String?

    private(set) var selected: Row?

    let data: [Row]

    init(attribute: ProductAttribute, selectedOption: ProductVariationAttribute?) {
        self.navigationBarTitle = attribute.name
        self.data = [Row.anyAttribute] + attribute.options.map { Row.option($0) }

        if let selectedOption = selectedOption {
            self.selected = .option(selectedOption.option)
        } else {
            self.selected = .anyAttribute
        }
    }

    func configureCell(cell: BasicTableViewCell, model: Row) {
        switch model {
        case .anyAttribute:
            cell.textLabel?.text = Localization.anyAttributeOption
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
        static let anyAttributeOption = NSLocalizedString(
            "Any Attribute",
            comment: "Product variation attribute description where the attribute is set to any value.")
    }
}
